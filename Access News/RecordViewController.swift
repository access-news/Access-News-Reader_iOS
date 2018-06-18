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
    var queuePlayer:      AVQueuePlayer?

    var articleChunks = [AVURLAsset]()

    @IBOutlet weak var disabledNotice: UITextView!

    @IBOutlet weak var playbackSlider: UISlider!
    @IBOutlet weak var recordCounter: UILabel!

    let disabledGrey = UIColor(red: 0.910, green: 0.910, blue: 0.910, alpha: 1.0)
    let playGreen    = UIColor(red: 0.238, green: 0.753, blue: 0.323, alpha: 1.0)
    let recordRed    = UIColor(red: 1.0,   green: 0.2,   blue: 0.169, alpha: 1.0)

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

        // recordButton is enabled by default

        self.playButton.isEnabled = false
        self.playButton.backgroundColor = self.disabledGrey

        self.stopButton.isEnabled = false
        self.stopButton.backgroundColor = self.disabledGrey

        self.submitButton.isHidden = true

        self.playbackSlider.isHidden = true
        self.recordCounter.textColor = self.disabledGrey
        /* --- */

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

        /* UI state */
        self.recordButton.isEnabled = false
        self.recordButton.backgroundColor = self.disabledGrey
        self.recordButton.setTitle("Continue", for: .normal)

        self.stopButton.isHidden = false
        self.stopButton.isEnabled = true
        self.stopButton.backgroundColor = .black

        self.submitButton.isHidden = true

        self.playButton.isEnabled = false
        self.playButton.backgroundColor = self.disabledGrey

        self.recordCounter.textColor = .black

        self.playbackSlider.isHidden = true
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
        }

        /* UI state */
        self.recordButton.isEnabled = true
        self.recordButton.backgroundColor = self.recordRed
        self.recordButton.setTitle("Continue", for: .normal)
        
        self.stopButton.isHidden = true
        
        self.submitButton.isHidden = false
        
        self.playButton.isEnabled = true
        self.playButton.backgroundColor = self.playGreen
        
        self.recordCounter.textColor = self.disabledGrey
        
        self.playbackSlider.isHidden = true
    }

    @IBOutlet weak var playButton: UIButton!
    @IBAction func playTapped(_ sender: Any) {

        self.startPlayer()

        /* UI state */
        self.recordButton.isEnabled = false
        self.recordButton.backgroundColor = self.disabledGrey
        self.recordButton.setTitle("Continue", for: .normal)

        self.stopButton.isHidden = false
        self.stopButton.isEnabled = true
        self.stopButton.backgroundColor = .black

        self.submitButton.isHidden = true

        self.playButton.isEnabled = false
        self.playButton.backgroundColor = self.disabledGrey

        self.recordCounter.textColor = .black

        self.playbackSlider.isHidden = false
    }

    @IBOutlet weak var submitButton: UIButton!
    @IBAction func submitTapped(_ sender: Any) {

        // TODO: Insert SubmitViewController

        /* UI state */
        self.recordButton.isEnabled = true
        self.recordButton.backgroundColor = self.recordRed
        self.recordButton.setTitle("Record", for: .normal)

        self.stopButton.isHidden = false
        self.stopButton.isEnabled = false
        self.stopButton.backgroundColor = self.disabledGrey

        self.submitButton.isHidden = true

        self.playButton.isEnabled = false
        self.playButton.backgroundColor = self.disabledGrey

        self.recordCounter.textColor = self.disabledGrey

        self.playbackSlider.isHidden = true
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

            // TODO: add audio recorder delegate? Interruptions (e.g., calls)
            //       are handled elsewhere anyway
            self.startRecTimer()

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
        let asset     = AVURLAsset(url: assetURL, options: assetOpts)

        self.articleChunks.append(asset)
    }

    func startPlayer() {
        let assetKeys = ["playable"]
        let playerItems = self.articleChunks.map {
            AVPlayerItem(asset: $0, automaticallyLoadedAssetKeys: assetKeys)
        }

        //        playerItem.addObserver(
        //            self,
        //            forKeyPath: #keyPath(AVPlayerItem.status),
        //            options:    [.old, .new],
        //            context:    &RecordViewController.playerItemContext)
        self.queuePlayer = AVQueuePlayer(items: playerItems)
        self.queuePlayer?.actionAtItemEnd = .advance

        self.queuePlayer?.play()
    }

    func stopPlayer() {
        self.queuePlayer?.pause()
        self.queuePlayer = nil
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

    func startRecTimer() {
        Timer.scheduledTimer(timeInterval: 0.01  , target: self, selector: #selector(self.updateRecTimerLabel), userInfo: nil, repeats: true)
    }

    // Currently in centiseconds (10^-2)
    var timerFraction : Double = 0.0

    @objc func updateRecTimerLabel(_ t: Timer) {

        func addOneSecToPart(_ s: Substring) -> String {
            self.timerFraction = 0.0
            return String(format: "%02u", Int(String(s))!+1)
        }

        func tick(_ label: String) -> String {
            let parts = label.split(separator: ":")

            switch (parts[0], parts[1], parts[2], self.timerFraction) {

            case (let p, "59", "59", 0.99):
                return [addOneSecToPart(p), "00", "00"].joined(separator: ":")

            case (let a, let b, "59", 0.99):
                return [String(a), addOneSecToPart(b), "00"].joined(separator: ":")

            case (let a, let b, let c, 0.99):
                return [String(a), String(b), addOneSecToPart(c)].joined(separator: ":")

            case (let a, let b, let c, _):
                self.timerFraction += 0.01
                return [String(a), String(b), String(c)].joined(separator: ":")
            }
        }

        let oldValue = self.recordCounter.text!
        self.recordCounter.text = tick(oldValue)
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
    func concatChunks() {
        let composition = AVMutableComposition()

        var insertAt = CMTimeRange(start: kCMTimeZero, end: kCMTimeZero)

        for asset in self.articleChunks {
            let assetTimeRange = CMTimeRange(
                start: kCMTimeZero,
                end:   asset.duration)

            do {
                try composition.insertTimeRange(assetTimeRange,
                                                of: asset,
                                                at: insertAt.end)
            } catch {
                NSLog("Unable to compose asset track.")
            }

            let nextDuration = insertAt.duration + assetTimeRange.duration
            insertAt = CMTimeRange(
                start:    kCMTimeZero,
                duration: nextDuration)
        }

        let exportSession =
            AVAssetExportSession(
                asset:      composition,
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
                for asset in self.articleChunks {
                    try! FileManager.default.removeItem(at: asset.url)
                }

                /* Resetting `articleChunks` here, because this function is
                 called asynchronously and calling it from `queueTapped` or
                 `submitTapped` may delete the files prematurely.
                 */
                self.articleChunks = [AVURLAsset]()

            case .failed?: break
            case .cancelled?: break
            case .none: break
            }
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
