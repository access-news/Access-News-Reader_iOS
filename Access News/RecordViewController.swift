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

    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var disabledNotice: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.disabledNotice.isHidden = true
        
        /* https://www.hackingwithswift.com/example-code/media/how-to-record-audio-using-avaudiorecorder
        */
        self.recordingSession = AVAudioSession.sharedInstance()
        do {
            
            try self.recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try self.recordingSession.setActive(true)
            
            self.recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {

                    if allowed != true {
                        self.disabledNotice.isHidden = false
                        self.recordButton.isHidden = true
                        self.stopButton.isHidden   = true
                        self.playButton.isHidden   = true
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
