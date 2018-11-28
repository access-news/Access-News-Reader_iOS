//
//  ShareViewController.swift
//  Access-News-Uploader
//
//  Created by Attila Gulyas on 10/22/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

// Finally managed to add Firebase and ilk to share extension in
// commit 4f7528cf5e90f5395b7fa47e22855a1367497763
// but here are the steps just to make sure:

//   Started receiving this error:
//   > `firebase 'sharedApplication' is unavailable: not
//   > available on iOS (App Extension) - Use view controller
//   > based solutions where appropriate instead.`

//   Tried a bazillion things, got fed up,

//   1. wiped everything clean by cloning the repo fresh from github,

//   2. deleted
//   + ~/Library/Developer/Xcode/DerivedData
//   + ./Pods/
//   + Podfile
//   + Podfile.lock

//   3. $ pod init

//   4. copied over the Podfile that's in this repo

//   5. $ pod update

//   Probably won't work next time.
///

import UIKit

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        /* This could've been done from the Object Library but for some reason
           the blurred view kept being deallocated. Doing it programmatically
           resulted in the same behaviour, but after a couple retries it seems
           that it is ok. Weird.
        */
        // https://stackoverflow.com/questions/17041669/creating-a-blurring-overlay-view/25706250
        // only apply the blur if the user hasn't disabled transparency effects
        if UIAccessibilityIsReduceTransparencyEnabled() == false {
            view.backgroundColor = .clear

            let blurEffect = UIBlurEffect(style: .dark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            //always fill the view
            blurEffectView.frame = self.view.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            view.insertSubview(blurEffectView, at: 0)
        } else {
            view.backgroundColor = .black
        }
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
