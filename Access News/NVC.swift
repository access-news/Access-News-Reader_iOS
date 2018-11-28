//
//  NVC.swift
//  Access News
//
//  Created by Attila Gulyas on 11/27/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

import UIKit
import FirebaseAuth

class NVC: UINavigationController {

    let defaults = UserDefaults.init(suiteName: "group.org.societyfortheblind.access-news-reader-ag")!

    override func viewDidLoad() {
        super.viewDidLoad()

        if self.defaults.bool(forKey: "user-logged-in") == false {
            let storyboard = UIStoryboard(name: "Main", bundle: .main)
            let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            loginViewController.navigationItem.hidesBackButton = true
            self.pushViewController(loginViewController, animated: false)
        }
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
