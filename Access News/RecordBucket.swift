//
//  RecordBucket.swift
//  Access News
//
//  Created by Attila Gulyas on 9/14/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

import UIKit
import AVFoundation

struct RecordBucket {

    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVPlayer?

    var recordTimer:  Timer!

    /* `self.timerLabel` only displays elapsed time, down to seconds,
     but `updateTimerLabel` (and therefore `self.tick()`) fires
     every 0.01 seconds. This global variable is used to check
     whether label update is necessary (i.e., did a full second
     already went by).
     */
//    var seconds : [String: String] =
//        [ "record and playback" : ""
//        , "session"  : ""
//        ]
    var seconds: String = ""

    var articleSoFar: AVMutableComposition! = AVMutableComposition()
    var latestChunk: AVURLAsset? = nil
    var insertAt: CMTimeRange! = CMTimeRange(start: kCMTimeZero, end: kCMTimeZero)

    /* To store reference to partial recordings. Unsure whether
     adding an AVAsset to an AVComposition copies the data or
     references them, therefore keeping their references here
     and removing the files when exporting.
     */
    var leftoverChunks = [AVURLAsset]()

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

    // https://stackoverflow.com/questions/35906568/wait-until-swift-for-loop-with-asynchronous-network-requests-finishes-executing
    let dispatchGroup = DispatchGroup()
    // https://stackoverflow.com/questions/45682622/swift-execute-asynchronous-tasks-in-order
    // http://iosbrain.com/blog/2018/03/07/concurrency-in-ios-serial-and-concurrent-queues-in-grand-central-dispatch-gcd-with-swift-4/
    var dispatchQueue: DispatchQueue = DispatchQueue(label: "bucket")
//    init(label: String) {
//        self.bucketQueue = DispatchQueue(label: label)
//    }

    /* Track whether slider has been tapped during playback or not.
     If yes, resume playback from the position the control has
     been released (i.e., touchUpInside).

     Initialized with `false` because playback will only start on
     tapping the Play button.
     */
    var slidingOnPlayback: Bool = false
}
