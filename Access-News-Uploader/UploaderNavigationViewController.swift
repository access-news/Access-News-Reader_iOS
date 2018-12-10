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

    override func viewDidLoad() {
        super.viewDidLoad()

        /* TODO:
         Should this config be in didSelectPost()`?
         See
         + https://stackoverflow.com/questions/49134868/how-to-officially-handle-unauthenticated-users-in-an-ios-share-extension/
         + https://stackoverflow.com/questions/41114967/how-to-add-firebase-to-today-extension-ios/48213902#48213902
         */
        // https://stackoverflow.com/questions/37910766/
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()

        }

        if CommonDefaults.defaults.string(forKey: "username") != "" {
            Auth.auth().signIn(
                withEmail: CommonDefaults.defaults.string(forKey: "username")!,
                password: CommonDefaults.defaults.string(forKey: "password")!) {
                    (user, error) in
                    if error != nil {
                        let errorCode = AuthErrorCode(rawValue: (error! as NSError).code)!

                        print("\n\n\(errorCode)\n\n")
                    } else {
                        print("\n\n\(String(describing: user?.user.uid))\n\n")
                    }
            }
        } else {
            print("\n\nnot logged in main\n\n")
        }

//        CommonDefaults.showLoginIfNoUser(navController: self)
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
