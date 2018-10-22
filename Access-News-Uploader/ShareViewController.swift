//
//  ShareViewController.swift
//  Access-News-Uploader
//
//  Created by Attila Gulyas on 10/22/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

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
        if !UIAccessibilityIsReduceTransparencyEnabled() {
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
