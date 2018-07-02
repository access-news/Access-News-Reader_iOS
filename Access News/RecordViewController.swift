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

    // Initialized in `viewDidLoad` via `zeroAudioArtifacts()`
    var articleSoFar: AVMutableComposition!
    var latestChunk: AVURLAsset?
    var insertAt: CMTimeRange!
    /* To store reference to partial recordings. Unsure whether adding an AVAsset
       to an AVComposition copies the data or references them, therefore keeping
       their references here and remove the files when exporting. */
    var leftoverChunks: [AVURLAsset]!
    // --------------------------------------------------------

    @IBOutlet weak var disabledNotice: UITextView!

    @IBOutlet weak var playbackSlider: UISlider!
    @IBOutlet weak var timerLabel: UILabel!

    let disabledGrey      = UIColor(red: 0.910, green: 0.910, blue: 0.910, alpha: 1.0)
    let playGreen         = UIColor(red: 0.238, green: 0.753, blue: 0.323, alpha: 1.0)
    let recordRed         = UIColor(red: 1.0,   green: 0.2,   blue: 0.169, alpha: 1.0)
    let startoverPurple   = UIColor(red: 0.633, green: 0.276, blue: 0.425, alpha: 1.0)
    let pausePlaybackGrey = UIColor(red: 0.475, green: 0.494, blue: 0.500, alpha: 1.0)

    var documentDir: URL {
        get {
            let documentURLs = FileManager.default.urls(
                for: .documentDirectory,
                in:  .userDomainMask
            )
            return documentURLs.first!
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Controls
    @IBOutlet weak var recordButton: UIButton!
    @IBAction func recordTapped(_ sender: Any) {

        self.startRecorder()

        self.recordUIState()
    }

    @IBOutlet weak var stopButton: UIButton!
    @IBAction func stopTapped(_ sender: Any) {

        /* If `self.audioRecorder` is not empty, that means that
           recording is in progress, otherwise it must be called
           when playing back audio.
        */
        if self.audioRecorder != nil {
            self.stopRecorder()
        } else {
            self.stopPlayer()
            // In this case, `restoreTimerLabel` would be more appropriate...
            self.updateRecordTimerLabel()
        }

        self.stoppedUIState()
    }

    @IBOutlet weak var playButton: UIButton!
    @IBAction func playTapped(_ sender: Any) {

        self.startPlayer()
        self.playUIState()
    }

    @IBOutlet weak var submitButton: UIButton!
    @IBAction func submitTapped(_ sender: Any) {

        // TODO: Insert SubmitViewController


        /* Does not need to invoke `self.zeroAudioArtifacts()` because
           `self.exportArticle()` calles it on successful completion.
        */
        self.resetRecordTimer()
        self.startUIState()
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
    }

    var timeObserverToken: Any?

    func startPlayer() {

        if self.audioPlayer == nil {

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

            /* ADD SLIDER

               http://swiftdeveloperblog.com/code-examples/add-playback-slider-to-avplayer-example-in-swift/
               Helpful to get the seeking with the slider set up, but does not say
               anything on how to integrate with `addPeriodicTimeObserver`.
            */

            let duration : CMTime  = self.audioPlayer!.currentItem!.duration
            let seconds  : Double = CMTimeGetSeconds(duration)

            self.playbackSlider.minimumValue = 0
            self.playbackSlider.maximumValue = Float(seconds)

            self.playbackSlider.setValue(0.0, animated: false)
            self.playbackSlider.isContinuous = true
            /* React if slider is being interacted with.
               (Not removed anywhere as invoking it multiple times shouldn't have
                any effect. Shouldn't.)
            */
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

            self.registerPeriodicTimeObserver()
        }

        self.audioPlayer?.play()
    }

    @objc func itemDidFinishPlaying() {
        self.stopPlayer()
        self.playagainUIState()
        self.slidingOnPlayback = false
    }


    /* Track whether slider has been tapped during playback or not.
       If yes, resume playback from the position the control has
       been released (i.e., touchUpInside).

       Initialized with `false` because playback only start on tapping
       the Play button.
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
        if self.slidingOnPlayback {
            self.startPlayer()
        }
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

    func registerPeriodicTimeObserver() {
        self.timeObserverToken =
            /* Register a method to fire every 0.01 second when playing audio.
             (Removed in `self.stopPlayer()`)
             */
            self.audioPlayer?.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
                queue: DispatchQueue.main) {
                    [weak self] time in

//                    print(CMTimeGetSeconds(time))
                    let t = CMTimeGetSeconds(time)
                    self?.tick(Double(t))

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

    var timer: Timer!

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

    func startRecordTimer() {

        self.timer = Timer.scheduledTimer(timeInterval: 0.01  , target: self, selector: #selector(updateRecordTimerLabel), userInfo: nil, repeats: true)
    }

    /* `self.timerLabel` only displays elapsed time down to seconds,
        but `updateTimerLabel` (and therefore `self.tick()`) fires
        every 0.01 seconds. This global variable is used to check
        whether label update is necessary (i.e., did a full second
        already elapsed).
    */
    var seconds: String!

    @objc func updateRecordTimerLabel() {

        let recorderTime =
            self.audioRecorder != nil
            ? self.audioRecorder!.currentTime
            : 0.0

        let elapsed =
              self.articleSoFarDuration
            + recorderTime

        self.tick(elapsed)
    }

    func tick(_ time: Double) {

        let elapsedSecond =
            String(String(time).prefix(while: { c in return c != "."}))

        if self.seconds != elapsedSecond {
            self.seconds = elapsedSecond
            let i = Int(elapsedSecond)!
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

            self.timerLabel.text = results.map { String(format: "%02u", $0)}.joined(separator: ":")
        }
    }

    func stopRecordTimer() {
        self.timer.invalidate()

        self.articleSoFarDuration = CMTimeGetSeconds(self.articleSoFar.duration)
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
        self.articleSoFarDuration = 0.0
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
        self.latestChunk = nil
        self.insertAt = CMTimeRange(start: kCMTimeZero, end: kCMTimeZero)
        self.leftoverChunks = [AVURLAsset]()
    }

    func exportArticle() {

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
        /* TODO?
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

        self.timerLabel.isHidden   = true
        self.playbackSlider.isHidden  = true
        self.startoverButton.isHidden = true
    }

    func recordUIState() {
        self.recordButton.isEnabled = false
        self.recordButton.backgroundColor = self.disabledGrey
        UIView.performWithoutAnimation {
            self.recordButton.setTitle("Continue", for: .normal)
            self.recordButton.layoutIfNeeded()
        }

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
        self.playbackSlider.isHidden  = true
        self.startoverButton.isHidden = true
    }

    func stoppedUIState() {
        self.recordButton.isEnabled = true
        self.recordButton.backgroundColor = self.recordRed
        UIView.performWithoutAnimation {
            self.recordButton.setTitle("Continue", for: .normal)
            self.recordButton.layoutIfNeeded()
        }

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

        self.timerLabel.isHidden   = false

        self.playbackSlider.isHidden  = true
        self.startoverButton.isHidden = false
    }

    func playUIState() {
        self.recordButton.isEnabled = false
        self.recordButton.backgroundColor = self.disabledGrey
        UIView.performWithoutAnimation {
            self.recordButton.setTitle("Continue", for: .normal)
            self.recordButton.layoutIfNeeded()
        }

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
        self.playbackSlider.isHidden  = false
        self.startoverButton.isHidden = true
    }

    func resumePlaybackUIState() {
        self.recordButton.isEnabled = false
        self.recordButton.backgroundColor = self.disabledGrey
        UIView.performWithoutAnimation {
            self.recordButton.setTitle("Continue", for: .normal)
            self.recordButton.layoutIfNeeded()
        }

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
        self.playbackSlider.isHidden  = false
        self.startoverButton.isHidden = true
    }

    func playagainUIState() {
        self.recordButton.isEnabled = false
        self.recordButton.backgroundColor = self.disabledGrey
        UIView.performWithoutAnimation {
            self.recordButton.setTitle("Continue", for: .normal)
            self.recordButton.layoutIfNeeded()
        }

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
            self.playButton.setTitle("Play Again", for: .normal)
            self.playButton.layoutIfNeeded()
        }

        self.timerLabel.isHidden   = false
        self.playbackSlider.isHidden  = false
        self.startoverButton.isHidden = true
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
