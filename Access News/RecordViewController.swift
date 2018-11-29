//
//  RecordViewController.swift
//  Access News
//
//  Created by Attila Gulyas on 6/1/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

import UIKit
import AVFoundation

class RecordViewController: UIViewController {

    @IBOutlet weak var playbackSlider: UISlider!
    @IBOutlet weak var sessionTimerLabel: UIBarButtonItem!
    @IBOutlet weak var timerLabel: UILabel!

    var documentDir: URL {
        get {
            let documentURLs = FileManager.default.urls(
                for: .documentDirectory,
                in:  .userDomainMask
            )
            return documentURLs.first!
        }
    }

    var sessionStartVC: SessionStartViewController {
        get {
            return self.navigationController?.viewControllers[0] as! SessionStartViewController
        }
    }

    let disabledGrey      = UIColor(red: 0.910, green: 0.910, blue: 0.910, alpha: 1.0)
    let playGreen         = UIColor(red: 0.238, green: 0.753, blue: 0.323, alpha: 1.0)
    let recordRed         = UIColor(red: 1.0,   green: 0.2,   blue: 0.169, alpha: 1.0)
    let endsessionPurple  = UIColor(red: 0.633, green: 0.276, blue: 0.425, alpha: 1.0)
    let pausePlaybackGrey = UIColor(red: 0.475, green: 0.494, blue: 0.500, alpha: 1.0)
    let startoverGold     = UIColor(red: 1.000, green: 0.694, blue: 0.0,   alpha: 1.0)

    var sessionTimer: Timer!
    var sessionDuration: Double = 0.0

    var recordBucket: RecordBucket!

    override func viewDidLoad() {
        super.viewDidLoad()

        /* Set default UI properties, assuming that permission to record is given. */
        self.startUIState()

        /* SESSION TIMER SETUP */
        self.sessionTimerLabel.title = "00:00:00"
        self.sessionTimer =
            Timer.scheduledTimer(
                timeInterval: 0.01,
                target: self,
                selector: #selector(self.updateSessionTimerLabel),
                userInfo: nil,
                repeats: true)
    }

    @objc func updateSessionTimerLabel(timer: Timer) {

        let newTime = self.sessionDuration + timer.timeInterval
        self.sessionDuration = newTime

        let newTimeSecondString = self.timeToSecondString(newTime)

        let shouldTick = self.tickOnceASec(secondString: newTimeSecondString, forTimer: "session")

        if shouldTick == true {
            self.sessionTimerLabel.title = self.convertSecondStringToTimerLabel(newTimeSecondString)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Controls
    @IBOutlet weak var recordButton: UIButton!
    @IBAction func recordTapped(_ sender: Any) {

        if recordButton.titleLabel?.text == "Record" {
            self.recordBucket = RecordBucket()
        }
        
        Commands.seqs[Aggregates.recording.rawValue] = 1

        self.startRecorder()
        self.recordUIState()
    }

    @IBOutlet weak var backButton: UIButton!
    @IBAction func backTapped(_ sender: Any) {
        self.stopPlayer()
        self.stoppedUIState()
    }

    @IBOutlet weak var stopButton: UIButton!
    @IBAction func stopTapped(_ sender: Any) {

        /* If `self.audioRecorder` is not empty, that means that
           recording is in progress, otherwise it must be called
           when playing back audio.
        */
        if self.recordBucket.audioRecorder != nil {
            self.stopRecorder()
            self.stoppedUIState()
        } else {
            /* Pausing instead of full stop (i.e., nil out `self.audioPlayer`),
               because if user tries to seek after stopping, the app will crash
               as there is no AVPlayer object (with the current asset) anymore.
            */
            self.pausePlayer()
            self.playagainUIState()

            // TODO: Hitting "Stop" during playback won't reset the slider.
            /*

             The slider reset is called in `playagainUIState` but it won't get
             honored, because my guess is that AVPlayer.pause is async therefore
             it still gets updated after the call. The second "Stop" press works,
             because AVPlayer is already stopped.

             The solution is to set up a KVO (not sure where yet) to check on
             AVPlayer's rate, and reset the slider there.
             https://stackoverflow.com/questions/7575494/avplayer-notification-for-play-pause-state
             See AVPlayer documentation as well (mentions KVO with rate)

             This is low priority and it only affects my OCD.
            */
        }
    }

    @IBOutlet weak var playButton: UIButton!
    @IBAction func playTapped(_ sender: Any) {

        if self.playButton.titleLabel?.text == "Play Again" {
            self.stopPlayer()
        }

        /* Set up AVPlayer, if it is not set up already. Without this check,
           if "Play" is tapped from `playbackUIState`, it will reinit the
           player (with its player item) ever single time) losing progress,
           and sliding/seeking won't be possible.

           If the `playbackUIState` is active, the player should only be started,
           without any configuration.
        */
        if self.recordBucket.audioPlayer == nil {
            self.initPlayer()
        }
        self.playbackUIState()
        self.startPlayer()
    }

    @IBOutlet weak var submitButton: UIButton!
    @IBAction func submitTapped(_ sender: Any) {
        /* self.exportArticle()
           self.resetRecordTimer()
           self.startUIState()

           These should only be invoked on successful submission,
           thus they can be found in SubmitTVC.
        */

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(
            UIAlertAction(
                title: "Submit",
                style: .default,
                handler: { _action in
                    let storyboard = UIStoryboard(name: "Main", bundle: .main)
                    let submitTVC = storyboard.instantiateViewController(withIdentifier: "SubmitTVC")
                    self.navigationController?.pushViewController(submitTVC, animated: true)
            }))
        actionSheet.addAction(
            UIAlertAction(
                title: "End Session",
                style: .default,
                handler: { _action in

                    Commands.updateSession(seconds: Int(self.sessionDuration), done: true)

                    /* User explicitly states with this action that they don't
                       intend to upload recording at this time, therefore only
                       exporting it. That can be done in the background as we
                       are not waiting for starting upload on the main thread.
                    */
                    /*
                     ! Timers need to be invalidated manually as they are
                     ! not part of RecordBucket.
                    */
                    self.recordBucket.dispatchQueue.async {
                        self.exportArticle(
                            bucket: self.recordBucket,
                            fileURL: self.createNewRecordingURL())
                    }
                    self.endSession()
            }))
        actionSheet.addAction(
            UIAlertAction(
                title: "Start New Recording",
                style: .default,
                handler: { _action in

                    self.recordBucket.dispatchQueue.async {
                        self.exportArticle(
                            bucket: self.recordBucket,
                            fileURL: self.createNewRecordingURL())
                    }
                    self.newRecording()
            }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(actionSheet, animated: true, completion: nil)
    }

    @IBOutlet weak var startoverButton: UIButton!
    @IBAction func startoverTapped(_ sender: Any) {

        self.deleteLeftoverChunks(bucket: self.recordBucket)
        self.newRecording()
    }

    func newRecording() {
        self.resetRecordTimer()
        self.startUIState()
    }

    func endSession() {

        Commands.updateSession(seconds: Int(self.sessionDuration), done: true)

        self.sessionTimer.invalidate()
        self.navigationController?.popToViewController(self.sessionStartVC as UIViewController, animated: true)
    }

    @IBOutlet weak var playbackPauseButton: UIButton!
    @IBAction func playbackPauseTapped(_ sender: Any) {

        self.pausePlayer()
        self.resumePlaybackUIState()
    }

    // MARK: - Audio commands

    func startRecorder() {
        let settings =
            [ AVFormatIDKey:             Int(kAudioFormatMPEG4AAC)
            , AVSampleRateKey:           44100
            , AVNumberOfChannelsKey:     1
            , AVEncoderAudioQualityKey:  AVAudioQuality.high.rawValue
            , AVEncoderBitRateKey:       128000
            ]

        let url = self.createNewRecordingURL()

        do {

            self.recordBucket.audioRecorder =
                try AVAudioRecorder.init(url: url, settings: settings)
            self.recordBucket.audioRecorder?.record()
            self.startRecordTimer()

            // TODO: add audio recorder delegate? Interruptions (e.g., calls)
            //       are handled elsewhere anyway

        } catch {
            NSLog("Unable to init audio recorder.")
        }
    }

    func stopRecorder() {
        self.recordBucket.audioRecorder?.stop()
        let assetURL = self.recordBucket.audioRecorder!.url
        self.recordBucket.audioRecorder = nil

        /* https://developer.apple.com/documentation/avfoundation/avurlassetpreferprecisedurationandtimingkey
         "If you intend to insert the asset into an AVMutableComposition
         object, precise random access is typically desirable, and the
         value of true is recommended."
         */
        let assetOpts = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        self.recordBucket.latestChunk = AVURLAsset(url: assetURL, options: assetOpts)
        self.appendChunk()

        self.stopRecordTimer()

        self.recordBucket.articleSoFarDuration = CMTimeGetSeconds(self.recordBucket.articleSoFar.duration)
    }

    func initPlayer() {
        let assetKeys = ["playable"]
        let playerItem =
            AVPlayerItem(
                asset: self.recordBucket.articleSoFar,
                automaticallyLoadedAssetKeys: assetKeys)

        /* Change UI if recording finished playing.
         (Removed in `self.stopPlayer()`)
         */
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.itemDidFinishPlaying),
            name:     .AVPlayerItemDidPlayToEndTime,
            object:   playerItem)

        self.recordBucket.audioPlayer = AVPlayer(playerItem: playerItem)
    }

    func startPlayer() {
        self.recordBucket.audioPlayer?.play()
    }

    @objc func itemDidFinishPlaying() {
        self.playagainUIState()
        self.recordBucket.slidingOnPlayback = false
    }

    func stopPlayer() {

        NotificationCenter.default.removeObserver(
            self,
            name:   .AVPlayerItemDidPlayToEndTime,
            object: self.recordBucket.audioPlayer?.currentItem)

        self.pausePlayer()
        self.removePeriodicTimeObserver()
        self.recordBucket.audioPlayer = nil
    }

    func pausePlayer() {
        self.recordBucket.audioPlayer?.pause()
    }

    // MARK: Audio command helpers

    func createNewRecordingURL() -> URL {
        let fileURL = CommonDefaults.nowString() + ".m4a"
        return self.documentDir.appendingPathComponent(fileURL)
    }

    func startRecordTimer() {

        self.recordBucket.recordTimer =
            Timer.scheduledTimer(
                timeInterval: 0.01,
                target: self,
                selector: #selector(updateRecordTimerLabel),
                userInfo: nil,
                repeats: true)
    }

    @objc func updateRecordTimerLabel() {

        let recorderTime =
            self.recordBucket.audioRecorder != nil
            ? self.recordBucket.audioRecorder!.currentTime
            : 0.0

        let elapsed =
              self.recordBucket.articleSoFarDuration
            + recorderTime

        let elapsedSecondString = self.timeToSecondString(elapsed)

        let shouldTick = self.tickOnceASec(secondString: elapsedSecondString, forTimer: "record and playback")

        if shouldTick == true {
            self.timerLabel.text = self.convertSecondStringToTimerLabel(elapsedSecondString)
        }
    }

    // 2.73429 -> "2"
    func timeToSecondString(_ time: Double) -> String {
        return String(String(time).prefix(while: { c in return c != "."}))
    }

    func tickOnceASec(secondString: String, forTimer: String) -> Bool {

        var seconds: String!
        if forTimer == "session" {
            seconds = self.sessionStartVC.seconds
        } else {
            seconds = self.recordBucket.seconds
        }

        if seconds != secondString {
            if forTimer == "session" {
                self.sessionStartVC.seconds = secondString
            } else {
                self.recordBucket.seconds = secondString
            }
            return true
        } else {
            return false
        }
    }

    // `from` is a "second string", which is basically an Int with quotes:
    // e.g., "27"
    func convertSecondStringToTimerLabel(_ secondString: String) -> String {
        let i = Int(secondString)!
        var results = [Int]()

        if i <= 3599 {
            let sec = i % 60
            let min = i / 60

            results = [0, min, sec]

        } else if i <= 215999 {
            let sec  = i % 60
            let tempMin = i / 60

            let min  = tempMin % 60
            let hour = tempMin / 60

            results = [hour, min, sec]
        }

       return results.map { String(format: "%02u", $0)}.joined(separator: ":")
    }

    // "timer label" is of the format "01:23:45" or "-01:23:45"
    func convertTimerLabelToSecondString(_ from: String) -> String {
        let timerLabelNoMinus = from.filter { $0 != "-" }

        let timerSections = timerLabelNoMinus.split(separator: ":")

        let seconds =          Int(timerSections[2])!
        let minutesToSeconds = Int(timerSections[1])! * 60
        let hoursToSeconds =   Int(timerSections[0])! * 60 * 60

        return String(seconds + minutesToSeconds + hoursToSeconds)
    }

    // Just an alias that corresponds to `startRecordTimer`
    func stopRecordTimer() {
        self.recordBucket.recordTimer.invalidate()
    }

    /* NOTE: Name may be misleading, but wanted to keep it in sync with
             `startRecordTimer` and `stopRecordTimer`.

             Timer is already invalidated in `stopRecordTimer` that shouldn't
             be an issue here, because this function will only be called from
             UI state where `stopRecordTimer` is already have been called.

             This only resets recording-related artifacts.
     */
    func resetRecordTimer() {
        self.timerLabel.text = "00:00:00"
    }

    /**
     Concatenates the audio parts created during recording. Invoked by `submitTapped`
     (i.e., tapping the `Submit` button).

     Using AVAudioRecorder is straightforward, it allows pausing as well, but it
     does not provide any ways to listen back the recording up to the point when
     the process was paused. The recording has to be stopped to get the data
     written to disk and to make it possible for a player (such as AVAudioPlayer,
     AVPlayer, AVQueuePlayer etc.) to play it back.

     See [How to create a pausable audio recording app on iOS](https://medium.com/scientific-breakthrough-of-the-afternoon/how-to-create-a-pausable-audio-recording-app-on-ios-9cc19d709356)
    */
    func appendChunk() {

        /* Using `self.articleChunk!` because it has to have content
           when the program execution gets here. If that is not the
           case, then I messed up somehow.
        */

        let chunkTimeRange = CMTimeRange(
            start: kCMTimeZero,
            end:   self.recordBucket.latestChunk!.duration)

        do {
            try self.recordBucket.articleSoFar.insertTimeRange(
                chunkTimeRange,
                of: self.recordBucket.latestChunk!,
                at: self.recordBucket.insertAt.end)
        } catch {
            NSLog("Unable to compose asset track.")
        }

        let nextDuration = self.recordBucket.insertAt.duration + chunkTimeRange.duration
        self.recordBucket.insertAt = CMTimeRange(
            start:    kCMTimeZero,
            duration: nextDuration)


        self.recordBucket.leftoverChunks.append(self.recordBucket.latestChunk!)

        // Making sure that this chunk is not lying around to mess things up later.
        self.recordBucket.latestChunk = nil
    }

    func deleteLeftoverChunks(bucket: RecordBucket) {
        /* Cleaning up partial recordings
         */
        for asset in bucket.leftoverChunks {
            try! FileManager.default.removeItem(at: asset.url)
        }
    }

    func exportArticle(bucket: RecordBucket, fileURL: URL) {

        bucket.dispatchGroup.enter()
        
        /* Redundant (when recording is stopped, `stopRecorder`
           call this already)
         */
        // if self.recordBucket.latestChunk != nil {
        //    self.appendChunk()
        // }

        let exportSession =
            AVAssetExportSession(
                asset:      bucket.articleSoFar,
                presetName: AVAssetExportPresetAppleM4A)

        exportSession?.outputFileType = AVFileType.m4a

        /* The class property articleURLToSubmit is also used to name the
           file to be uploaded in SubmitTVC.
        */

        exportSession?.outputURL = fileURL

        // Leaving here for debugging purposes.
        // exportSession?.outputURL = self.createNewRecordingURL("exported-")
        // TODO: #36
        // exportSession?.metadata = ...
        exportSession?.canPerformMultiplePassesOverSourceMediaData = true
        /* TODO? According to the docs, if multiple passes are enabled and
         "When the value of this property is nil, the export session
         will choose a suitable location when writing temporary files."
         */
        // exportSession?.directoryForTemporaryFiles = ...
        /* TODO:
         Listing all cases for completeness sake, but may just use `.completed`
         and ignore the rest with a `default` clause.
         OR
         because the completion handler is run async, KVO would be more appropriate
         */

        exportSession?.exportAsynchronously {

            switch exportSession?.status {
            case .unknown?: break
            case .waiting?: break
            case .exporting?: break

            case .completed?:
                /* Not calling `zeroRecordArtifacts` as a new RecordBucket is instantiated
                 on submit (i.e., hitting "Done") therefore only the leftover chunks
                 need to be cleaned up.

                 ! Timers need to be invalidated manually as they are not part of
                 ! RecordBucket.
                 */
                self.deleteLeftoverChunks(bucket: bucket)
                bucket.dispatchGroup.leave()

            case .failed?: break
            case .cancelled?: break
            case .none: break
            }
        }
    }

    // MARK: - UI states

    func startUIState() {
        self.sessionTimerLabel.tintColor = pausePlaybackGrey
        self.recordButton.isEnabled = true
        self.recordButton.backgroundColor = self.recordRed
        // https://stackoverflow.com/questions/18946490/how-to-stop-unwanted-uibutton-animation-on-title-change
        UIView.performWithoutAnimation {
            self.recordButton.setTitle("Record", for: .normal)
            self.recordButton.layoutIfNeeded()
        }

        self.backButton.isHidden = true

        self.playbackPauseButton.isHidden = true

        self.stopButton.isHidden = false
        self.stopButton.isEnabled = false
        self.stopButton.backgroundColor = self.disabledGrey
        UIView.performWithoutAnimation {
            self.stopButton.setTitle("Stop/Pause", for: .normal)
            self.stopButton.layoutIfNeeded()
        }

        self.submitButton.isHidden = false

        self.playButton.isEnabled = false
        self.playButton.backgroundColor = self.disabledGrey

        self.startoverButton.isHidden = true

        self.timerLabel.isHidden   = true
        self.playbackSlider.isHidden  = true

        /* --- */

        /* PLAYBACK TIMER TAP GESTURE SETUP
           (i.e., switch between up and down timer)

         `timerLabel` is used for both playback and recording. It should
         only respond to taps during playback, therefore user interaction
         for `timerLabel` is enabled in `playbackUIState` and disabled in
         ` recordUIState` below.
         */
        let playbackTimerLabelTapGesture =
            UITapGestureRecognizer(
                target: self,
                action: #selector(playbackTimerLabelTapped))
        playbackTimerLabelTapGesture.numberOfTapsRequired = 1

        self.timerLabel.addGestureRecognizer(playbackTimerLabelTapGesture)
        /* --- */
    }

    func recordUIState() {
        self.recordButton.isEnabled = false
        self.recordButton.backgroundColor = self.disabledGrey
        UIView.performWithoutAnimation {
            self.recordButton.setTitle("Continue", for: .normal)
            self.recordButton.layoutIfNeeded()
        }

        self.backButton.isHidden = true

        self.playbackPauseButton.isHidden = true

        self.stopButton.isHidden = false
        self.stopButton.isEnabled = true
        self.stopButton.backgroundColor = .black
        UIView.performWithoutAnimation {
            self.stopButton.setTitle("Stop/Pause", for: .normal)
            self.stopButton.layoutIfNeeded()
        }

        self.submitButton.isHidden = true

        self.playButton.isEnabled = false
        self.playButton.backgroundColor = self.disabledGrey

        self.timerLabel.isHidden   = false
        self.startoverButton.isHidden = true

        self.playbackSlider.isHidden  = true

        /* See "`timerLabel` TAP GESTURE SETUP" comment in
           `startUIState`
        */
        self.timerLabel.isUserInteractionEnabled = false
    }

    func stoppedUIState() {
        self.recordButton.isEnabled = true
        self.recordButton.backgroundColor = self.recordRed
        UIView.performWithoutAnimation {
            self.recordButton.setTitle("Continue", for: .normal)
            self.recordButton.layoutIfNeeded()
        }

        self.backButton.isHidden = true

        self.playbackPauseButton.isHidden = true

        self.stopButton.isHidden = true

        self.submitButton.isHidden = false

        self.playButton.isHidden = false
        self.playButton.isEnabled = true
        self.playButton.backgroundColor = self.playGreen
        UIView.performWithoutAnimation {
            self.playButton.setTitle("Play", for: .normal)
            self.playButton.layoutIfNeeded()
        }

        self.timerLabel.isHidden   = true
        self.startoverButton.isHidden = false

        self.playbackSlider.isHidden  = true
    }

    func playbackUIState() {
        self.resetRecordTimer()

        self.recordButton.isEnabled = false
        self.recordButton.backgroundColor = self.disabledGrey
        UIView.performWithoutAnimation {
            self.recordButton.setTitle("Continue", for: .normal)
            self.recordButton.layoutIfNeeded()
        }

        self.backButton.isHidden = false

        self.playbackPauseButton.isHidden = false

        self.stopButton.isHidden = false
        self.stopButton.isEnabled = true
        self.stopButton.backgroundColor = .black
        UIView.performWithoutAnimation {
            self.stopButton.setTitle("Stop", for: .normal)
            self.stopButton.layoutIfNeeded()
        }

        self.submitButton.isHidden = true

        self.playButton.isHidden = true

        self.timerLabel.isHidden   = false
        self.startoverButton.isHidden = true

        self.playbackSlider.isHidden  = false

        /* UISlider SETUP */

            let seconds  : Double = self.recordBucket.articleSoFarDuration

            self.playbackSlider.minimumValue = 0
            self.playbackSlider.maximumValue = Float(seconds)

            self.playbackSlider.setValue(0.0, animated: false)
            self.playbackSlider.isContinuous = true
            // React if slider is being interacted with.
            // (Not removed anywhere as invoking it multiple times shouldn't have
            // any effect. Shouldn't.)
            self.playbackSlider.addTarget(
                self,
                action: #selector(self.touchdownSlider),
                for: .touchDown)

            self.playbackSlider.addTarget(
                self,
                action: #selector(self.isSliding),
                for: .valueChanged)

            self.playbackSlider.addTarget(
                self,
                action: #selector(self.touchupinsideSlider),
                for: .touchUpInside)

            // Update slider periodically during playback.
            // (Removed in `self.stopPlayer`)

            // TODO: This is a bit messy, figure out a cleaner way.
            self.registerPeriodicTimeObserver()
        /* --- */


        /* See "`timerLabel` TAP GESTURE SETUP" comment in
         `startUIState`
         */
        self.timerLabel.isUserInteractionEnabled = true
    }

    func resumePlaybackUIState() {
        self.recordButton.isEnabled = false
        self.recordButton.backgroundColor = self.disabledGrey
        UIView.performWithoutAnimation {
            self.recordButton.setTitle("Continue", for: .normal)
            self.recordButton.layoutIfNeeded()
        }

        self.backButton.isHidden = false

        self.playbackPauseButton.isHidden = true

        self.stopButton.isHidden = false
        self.stopButton.isEnabled = true
        self.stopButton.backgroundColor = .black
        UIView.performWithoutAnimation {
            self.stopButton.setTitle("Stop", for: .normal)
            self.stopButton.layoutIfNeeded()
        }

        self.submitButton.isHidden = true

        self.playButton.isHidden = false
        UIView.performWithoutAnimation {
            self.playButton.setTitle("Play", for: .normal)
            self.playButton.layoutIfNeeded()
        }

        self.timerLabel.isHidden   = false
        self.startoverButton.isHidden = true

        self.playbackSlider.isHidden  = false
    }

    func playagainUIState() {
        self.recordButton.isEnabled = false
        self.recordButton.backgroundColor = self.disabledGrey
        UIView.performWithoutAnimation {
            self.recordButton.setTitle("Continue", for: .normal)
            self.recordButton.layoutIfNeeded()
        }

        self.backButton.isHidden = false

        self.playbackPauseButton.isHidden = true

        self.stopButton.isHidden = false
        self.stopButton.isEnabled = false
        self.stopButton.backgroundColor = self.disabledGrey
        UIView.performWithoutAnimation {
            self.stopButton.setTitle("Stop", for: .normal)
            self.stopButton.layoutIfNeeded()
        }

        self.submitButton.isHidden = true

        self.playButton.isHidden = false
        UIView.performWithoutAnimation {
            self.playButton.setTitle("Play Again", for: .normal)
            self.playButton.layoutIfNeeded()
        }

        self.timerLabel.isHidden   = false
        self.resetRecordTimer();

        self.startoverButton.isHidden = true

        self.playbackSlider.isHidden  = false
        self.playbackSlider.value = 0
    }

    // MARK: `timerLabel` tap gesture callback

    @objc func playbackTimerLabelTapped() {
        self.recordBucket.timerLabelReversed = !self.recordBucket.timerLabelReversed

        // Tap interaction with the `timerLabel` in only enable during playback,
        // and the reversal should be done here and not `updatePlayerTimerLabel`
        // (otherwise it would check and do a reverse every centisecond and not
        // just once, in the moment of the tap)

        let timerLabelSecondString =
            self.convertTimerLabelToSecondString(self.timerLabel.text!)

        self.timerLabel.text = self.reverseTimerLabel(secondString: timerLabelSecondString)
    }

    // accepts a "second string" (e.g., "27")
    func reverseTimerLabel(secondString ss: String) -> String {

        let secondString = self.convertTimerLabelToSecondString(self.timerLabel.text!)
        let reversedSecond = Int(self.recordBucket.articleSoFarDuration) - Int(secondString)!
        let reversedTimerLabel =
            self.convertSecondStringToTimerLabel(
                String(reversedSecond)
            )
        if self.recordBucket.timerLabelReversed == true {
            return "-" + reversedTimerLabel
        } else {
            return reversedTimerLabel
        }
    }

    // MARK: `playbackSlider` function for UIState methods

    // TODO: I just realized that the observer is also responsible for
    //       the `timerLabel` update... Leave it be for a while, and
    //       refactor once testing begins.

    var timeObserverToken: Any?

    func registerPeriodicTimeObserver() {
        self.timeObserverToken =
            /* Register a method to fire every 0.01 second when playing audio.
             (Removed in `self.stopPlayer()`)
             */
            self.recordBucket.audioPlayer?.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
                queue:       DispatchQueue.main) {
                    [weak self] time in

                    let t = CMTimeGetSeconds(time)
                    let timeSecondString = self?.timeToSecondString(t)

                    let shouldTick = self?.tickOnceASec(secondString: timeSecondString!, forTimer: "record and playback")

                    if shouldTick == true {

                        var newTimerLabel: String!

                        if self?.recordBucket.timerLabelReversed == true {
                            let reverseSecond =
                                Int((self?.recordBucket.articleSoFarDuration)!) - Int(timeSecondString!)!
                            newTimerLabel =
                                "-"
                                + (self?.convertSecondStringToTimerLabel(String(reverseSecond)))!
                        } else {
                            newTimerLabel =
                                self?.convertSecondStringToTimerLabel(timeSecondString!)
                        }

                        self?.timerLabel.text = newTimerLabel
                    }

                    let newSliderValue = Float(t)
                    self?.playbackSlider.setValue(
                        newSliderValue,
                        animated: true)
        }
    }

    func removePeriodicTimeObserver() {
        // If a time observer exists, remove it
        if let token = self.timeObserverToken {
            self.recordBucket.audioPlayer!.removeTimeObserver(token)
            self.timeObserverToken = nil
        }
    }

    @objc func touchdownSlider() {
        if self.recordBucket.audioPlayer!.rate != 0 { // i.e. playing
            self.pausePlayer()
            self.recordBucket.slidingOnPlayback = true
        }
    }

    @objc func isSliding() {

        let targetTime =
            CMTime(
                seconds: Double(self.playbackSlider.value),
                preferredTimescale: 100)

        self.recordBucket.audioPlayer!.seek(to: targetTime)
    }

    @objc func touchupinsideSlider() {
        /* When sliding all the way to the end, the label does not change
         to "Play Again", but after pressing "Play", it turns to "Pause",
         and switches to "Play Again".
         */
        if self.recordBucket.slidingOnPlayback {
            self.startPlayer()
            self.recordBucket.slidingOnPlayback = false
        } else if self.playbackSlider.maximumValue != self.playbackSlider.value {
            self.resumePlaybackUIState()
        } else {
            self.playagainUIState()
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}
