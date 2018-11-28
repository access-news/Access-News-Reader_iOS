//
//  UploaderNavigationViewController.swift
//  Access-News-Uploader
//
//  Created by Attila Gulyas on 11/14/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

import UIKit
import Firebase

class UploaderNavigationViewController: UINavigationController {

    let defaults = UserDefaults.init(suiteName: "group.org.societyfortheblind.access-news-reader-ag")!

    override func viewDidLoad() {
        super.viewDidLoad()

        /* TODO:
         Should this config be in didSelectPost()`?
         See http://www.talkmobiledev.com/2016/11/19/using-firebase-in-a-share-extension/
         */
        // https://stackoverflow.com/questions/37910766/
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        if self.defaults.bool(forKey: "user-logged-in") == false {
            let storyboard = UIStoryboard(name: "Main", bundle: .main)
            let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            loginViewController.navigationItem.hidesBackButton = true
            self.pushViewController(loginViewController, animated: false)
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
