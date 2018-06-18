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

    @IBOutlet weak var disabledNotice: UITextView!

    @IBOutlet weak var playbackSlider: UISlider!
    @IBOutlet weak var recordCounter: UILabel!

    let disabledGrey = UIColor(red: 0.910, green: 0.910, blue: 0.910, alpha: 1.0)
    let playGreen    = UIColor(red: 0.238, green: 0.753, blue: 0.323, alpha: 1.0)
    let recordRed    = UIColor(red: 1.0,   green: 0.2,   blue: 0.169, alpha: 1.0)

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
