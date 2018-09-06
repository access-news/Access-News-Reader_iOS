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

    var recordingSession: AVAudioSession!
    var audioRecorder:    AVAudioRecorder?
    var audioPlayer:      AVPlayer?

    var articleURLToSubmit: URL!
    // Initialized in `viewDidLoad` via `zeroAudioArtifacts()`
    var articleSoFar: AVMutableComposition!
    var latestChunk: AVURLAsset?
    var insertAt: CMTimeRange!
    /* To store reference to partial recordings. Unsure whether adding an AVAsset
       to an AVComposition copies the data or references them, therefore keeping
       their references here and removing the files when exporting. */
    var leftoverChunks: [AVURLAsset]!
    // --------------------------------------------------------

    @IBOutlet weak var disabledNotice: UITextView!

    @IBOutlet weak var playbackSlider: UISlider!


    let disabledGrey      = UIColor(red: 0.910, green: 0.910, blue: 0.910, alpha: 1.0)
    let playGreen         = UIColor(red: 0.238, green: 0.753, blue: 0.323, alpha: 1.0)
    let recordRed         = UIColor(red: 1.0,   green: 0.2,   blue: 0.169, alpha: 1.0)
    let endsessionPurple  = UIColor(red: 0.633, green: 0.276, blue: 0.425, alpha: 1.0)
    let pausePlaybackGrey = UIColor(red: 0.475, green: 0.494, blue: 0.500, alpha: 1.0)
    let startoverGold     = UIColor(red: 1.000, green: 0.694, blue: 0.0,   alpha: 1.0)

    @IBOutlet weak var sessionTimerLabel: UIBarButtonItem!

    var documentDir: URL {
        get {
            let documentURLs = FileManager.default.urls(
                for: .documentDirectory,
                in:  .userDomainMask
            )
            return documentURLs.first!
        }
    }

    /* `self.timerLabel` only displays elapsed time, down to seconds,
     but `updateTimerLabel` (and therefore `self.tick()`) fires
     every 0.01 seconds. This global variable is used to check
     whether label update is necessary (i.e., did a full second
     already went by).
     */
    var seconds : [String: String] =
        [ "record and playback" : ""
        , "session"  : ""
        ]

    var sessionTimer: Timer!
    var sessionDuration: Double!

    @IBOutlet weak var timerLabel: UILabel!
    var recordTimer:  Timer!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.sessionTimerLabel.tintColor = pausePlaybackGrey
        /* Set default UI properties, assuming that permission to record is given. */

        self.disabledNotice.isHidden = true
        self.zeroRecordArtifacts()
        self.startUIState()

        /* Set up audio session for recording and ask permission
           https://www.hackingwithswift.com/example-code/media/how-to-record-audio-using-avaudiorecorder
         */
        self.recordingSession = AVAudioSession.sharedInstance()
        do {

            try self.recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try self.recordingSession.setActive(true)

            self.recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {

                    if allowed != true {
                        self.disabledNotice.isHidden = false
                        self.recordButton.superview?.isHidden = true
                    }
                }
            }
        } catch {
            print("Setting up audiosession failed somehow.")
        }

        /* SESSION TIMER SETUP */
        self.sessionTimerLabel.title = "00:00:00"
        self.sessionDuration = 0.0
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

        let shouldTick = self.tickOnceASec(secondString: newTimeSecondString, timer: "session")

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
        if self.audioRecorder != nil {
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
        if self.audioPlayer == nil {
            self.initPlayer()
        }
        self.playbackUIState()
        self.startPlayer()
    }

    @IBOutlet weak var submitButton: UIButton!
    @IBAction func submitTapped(_ sender: Any) {

        // TODO: Insert SubmitViewController


        /* Does not need to invoke `self.zeroAudioArtifacts()` because
           `self.exportArticle()` calls it on successful completion.
        */
        self.exportArticle()

        /* These should only be invoked on successful submission! */
//        self.resetRecordTimer()
//        self.startUIState()
    }

    @IBOutlet weak var startoverButton: UIButton!
    @IBAction func startoverTapped(_ sender: Any) {
        /* Zeroing out whatever has been recorded up to
         this point.
         */
        self.zeroRecordArtifacts()
        self.resetRecordTimer()
        self.startUIState()
    }

    @IBOutlet weak var endsessionButton: UIButton!
    @IBAction func endsessionTapped(_ sender: Any) {

        Commands.updateSession(seconds: Int(self.sessionDuration), done: true)

        self.zeroRecordArtifacts()
        self.sessionTimer.invalidate()
        self.navigationController?.popViewController(animated: true)
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

            self.audioRecorder =
                try AVAudioRecorder.init(url: url, settings: settings)
            self.audioRecorder?.record()

            self.startRecordTimer()

            // TODO: add audio recorder delegate? Interruptions (e.g., calls)
            //       are handled elsewhere anyway

        } catch {
            NSLog("Unable to init audio recorder.")
        }
    }

    func stopRecorder() {
        self.audioRecorder?.stop()
        let assetURL = self.audioRecorder!.url
        self.audioRecorder = nil

        /* https://developer.apple.com/documentation/avfoundation/avurlassetpreferprecisedurationandtimingkey
         "If you intend to insert the asset into an AVMutableComposition
         object, precise random access is typically desirable, and the
         value of true is recommended."
         */
        let assetOpts = [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        self.latestChunk = AVURLAsset(url: assetURL, options: assetOpts)
        self.appendChunk()

        self.stopRecordTimer()

        self.articleSoFarDuration = CMTimeGetSeconds(self.articleSoFar.duration)
    }

    func initPlayer() {
        let assetKeys = ["playable"]
        let playerItem =
            AVPlayerItem(
                asset: self.articleSoFar,
                automaticallyLoadedAssetKeys: assetKeys)

        /* Change UI if recording finished playing.
         (Removed in `self.stopPlayer()`)
         */
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.itemDidFinishPlaying),
            name:     .AVPlayerItemDidPlayToEndTime,
            object:   playerItem)

        self.audioPlayer = AVPlayer(playerItem: playerItem)
    }

    func startPlayer() {
        self.audioPlayer?.play()
    }

    @objc func itemDidFinishPlaying() {
        self.playagainUIState()
        self.slidingOnPlayback = false
    }

    func stopPlayer() {

        NotificationCenter.default.removeObserver(
            self,
            name:   .AVPlayerItemDidPlayToEndTime,
            object: self.audioPlayer?.currentItem)

        self.pausePlayer()
        self.removePeriodicTimeObserver()
        self.audioPlayer = nil
    }

    func pausePlayer() {
        self.audioPlayer?.pause()
    }

    // MARK: Audio command helpers

    func dateString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"

        return dateFormatter.string(from: date)
    }

    func nowString() -> String {
        return self.dateString(Date())
    }

    func createNewRecordingURL() -> URL {
        let fileURL = self.nowString() + ".m4a"

        return self.documentDir.appendingPathComponent(fileURL)
    }

    /* Because paused AVAudioRecorder recording cannot be played
       back, it needs to be stopped (zeroing out its `currentTime`
       property as well), but the user should be able to resume
       recording from this point, seeing the timer updated from there.
       Hence this global variable.

       Updated from `stopRecordTimer` because once recording is
       stopped, if

       * "Continue" (recording) button is pressed, this would init,
         `updateTimerLabel`, called periodically from the timer below.

       * "Play" is tapped, it would be used to restore the timer
         label once returned from the playback UI. (Plus recording
         could be resumed, as described in the previous item.)

    */
    var articleSoFarDuration: Double = 0.0

    var timerLabelReversed: Bool = false

    func startRecordTimer() {

        self.recordTimer =
            Timer.scheduledTimer(
                timeInterval: 0.01,
                target: self,
                selector: #selector(updateRecordTimerLabel),
                userInfo: nil,
                repeats: true)
    }

    @objc func updateRecordTimerLabel() {

        let recorderTime =
            self.audioRecorder != nil
            ? self.audioRecorder!.currentTime
            : 0.0

        let elapsed =
              self.articleSoFarDuration
            + recorderTime

        let elapsedSecondString = self.timeToSecondString(elapsed)

        let shouldTick = self.tickOnceASec(secondString: elapsedSecondString, timer: "record and playback")

        if shouldTick == true {
            self.timerLabel.text = self.convertSecondStringToTimerLabel(elapsedSecondString)
        }
    }

    // 2.73429 -> "2"
    func timeToSecondString(_ time: Double) -> String {
        return String(String(time).prefix(while: { c in return c != "."}))
    }

    func tickOnceASec(secondString: String, timer: String) -> Bool {

        if self.seconds[timer] != secondString {
            self.seconds[timer] = secondString

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
        self.recordTimer.invalidate()
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
            end:   self.latestChunk!.duration)

        do {
            try self.articleSoFar.insertTimeRange(
                chunkTimeRange,
                of: self.latestChunk!,
                at: self.insertAt.end)
        } catch {
            NSLog("Unable to compose asset track.")
        }

        let nextDuration = self.insertAt.duration + chunkTimeRange.duration
        self.insertAt = CMTimeRange(
            start:    kCMTimeZero,
            duration: nextDuration)


        self.leftoverChunks.append(self.latestChunk!)

        // Making sure that this chunk is not lying around to mess things up later.
        self.latestChunk = nil
    }

    func zeroRecordArtifacts() {
        self.articleSoFar = AVMutableComposition()
        self.articleSoFarDuration = 0.0
        self.latestChunk = nil
        self.insertAt = CMTimeRange(start: kCMTimeZero, end: kCMTimeZero)
        self.leftoverChunks = [AVURLAsset]()
    }

    // https://stackoverflow.com/questions/35906568/wait-until-swift-for-loop-with-asynchronous-network-requests-finishes-executing
    let exportCheck = DispatchGroup()
    var articleDuration: Float64 = 0.0

    func exportArticle() {

        self.exportCheck.enter()

        /* Making sure that `self.articleSoFar` (AVMutableComposition) already contains
           the very last `self.articleChunk` (AVURLAsset).
         */
        if self.latestChunk != nil {
            self.appendChunk()
        }

        let exportSession =
            AVAssetExportSession(
                asset:      self.articleSoFar,
                presetName: AVAssetExportPresetAppleM4A)

        exportSession?.outputFileType = AVFileType.m4a
        /* TODO: Either set up metadata info or provide publication info
           later in filename from Submit form.
         */
        exportSession?.outputURL = self.createNewRecordingURL()
        self.articleURLToSubmit = exportSession?.outputURL
        self.articleDuration = CMTimeGetSeconds(self.articleSoFar.duration)

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

                self.exportCheck.leave()

                /* Cleaning up partial recordings
                 */
                for asset in self.leftoverChunks {
                    try! FileManager.default.removeItem(at: asset.url)
                }

                /* Resetting `articleChunks` here, because this function is
                 called asynchronously and calling it from `queueTapped` or
                 `submitTapped` may delete the files prematurely.
                 */
                self.zeroRecordArtifacts()

            case .failed?: break
            case .cancelled?: break
            case .none: break
            }
        }
    }

    // MARK: - UI states

    func startUIState() {
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

        self.submitButton.isHidden = true

        self.playButton.isEnabled = false
        self.playButton.backgroundColor = self.disabledGrey

        self.startoverButton.isHidden = true

        self.timerLabel.isHidden   = true
        self.playbackSlider.isHidden  = true
        self.endsessionButton.isHidden = true

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

    func restartUIState() {
        self.startUIState()
        self.endsessionButton.isEnabled = true
        self.endsessionButton.isHidden  = false
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
        self.endsessionButton.isHidden = true

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
        self.endsessionButton.isHidden = false
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
        self.endsessionButton.isHidden = true

        /* UISlider SETUP */

            let seconds  : Double = self.articleSoFarDuration

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
        self.endsessionButton.isHidden = true
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

        self.endsessionButton.isHidden = true
    }

    // MARK: `timerLabel` tap gesture callback

    @objc func playbackTimerLabelTapped() {
        self.timerLabelReversed = !self.timerLabelReversed

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
        let reversedSecond = Int(self.articleSoFarDuration) - Int(secondString)!
        let reversedTimerLabel =
            self.convertSecondStringToTimerLabel(
                String(reversedSecond)
            )
        if self.timerLabelReversed == true {
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
            self.audioPlayer?.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
                queue:       DispatchQueue.main) {
                    [weak self] time in

                    let t = CMTimeGetSeconds(time)
                    let timeSecondString = self?.timeToSecondString(t)

                    let shouldTick = self?.tickOnceASec(secondString: timeSecondString!, timer: "record and playback")

                    if shouldTick == true {

                        var newTimerLabel: String!

                        if self?.timerLabelReversed == true {
                            let reverseSecond =
                                Int((self?.articleSoFarDuration)!) - Int(timeSecondString!)!
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
            self.audioPlayer!.removeTimeObserver(token)
            self.timeObserverToken = nil
        }
    }

    /* Track whether slider has been tapped during playback or not.
     If yes, resume playback from the position the control has
     been released (i.e., touchUpInside).

     Initialized with `false` because playback will only start on
     tapping the Play button.
     */
    var slidingOnPlayback: Bool = false

    @objc func touchdownSlider() {
        if self.audioPlayer!.rate != 0 { // i.e. playing
            self.pausePlayer()
            self.slidingOnPlayback = true
        }
    }

    @objc func isSliding() {

        let targetTime =
            CMTime(
                seconds: Double(self.playbackSlider.value),
                preferredTimescale: 100)

        self.audioPlayer!.seek(to: targetTime)
    }

    @objc func touchupinsideSlider() {
        /* When sliding all the way to the end, the label does not change
         to "Play Again", but after pressing "Play", it turns to "Pause",
         and switches to "Play Again".
         */
        if self.slidingOnPlayback {
            self.startPlayer()
            self.slidingOnPlayback = false
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
