//
//  SessionStartViewController.swift
//  Access News
//
//  Created by Attila Gulyas on 7/3/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

class SessionStartViewController: UIViewController {

    var seconds: String = ""

    @IBOutlet weak var startSessionButton: UIButton!
    @IBAction func startSessionTapped(_ sender: Any) {

        // https://stackoverflow.com/questions/24981333/ios-check-if-application-has-access-to-microphone
        if AVAudioSession.sharedInstance().recordPermission() == .granted {

            Commands.seqs[Aggregates.session.rawValue] = 1
            Commands.startSession()

            let storyboard = UIStoryboard(name: "Main", bundle: .main)
            let recordVC = storyboard.instantiateViewController(withIdentifier: "RecordViewController")

            self.navigationController?.pushViewController(recordVC, animated: true)
        } else {
            // https://stackoverflow.com/questions/28152526/how-do-i-open-phone-settings-when-a-button-is-clicked
            let alert = UIAlertController(
                title: "Recording not allowed",
                message: "Please provide permission to use\nthe microphone in this app in\nSettings > Privacy > Microphone",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: {
                success in
                let settingsURL = URL(string: UIApplicationOpenSettingsURLString)
                if UIApplication.shared.canOpenURL(settingsURL!) {
                    UIApplication.shared.open(settingsURL!, options: [:], completionHandler: nil)
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /* Adding listener to update `seq` because user is signed in for sure
           at this point.
        */
        // Commands.seqUpdater()
        /* See comments in Commands why this is commented out. */

        self.navigationItem.rightBarButtonItem =
            UIBarButtonItem(title:  "Sign out",
                            style:  .plain,
                            target: self,
                            action: #selector(signOutTapped))
    }

    @objc func signOutTapped() {
        do {
            try Auth.auth().signOut()

            // Remove user credentials from the keychain
            // https://developer.apple.com/documentation/security/keychain_services/keychain_items/searching_for_keychain_items
            // https://developer.apple.com/documentation/security/keychain_services/keychain_items/updating_and_deleting_keychain_items

            enum KeychainError: Error {
                case noPassword
                case unexpectedPasswordData
                case unhandledError(status: OSStatus)
            }

            let query: [String: Any] =
                [ kSecClass as String:           kSecClassGenericPassword
                , kSecAttrGeneric as String:     CommonDefaults.userID()
                , kSecAttrAccessGroup as String: "K6BD7WSV5V.org.societyfortheblind.Access-News-Reader-kg"
                ]

            let status = SecItemDelete(query as CFDictionary)

            guard status == errSecSuccess || status == errSecItemNotFound
                else {throw KeychainError.unhandledError(status: status)}

//            let alert = UIAlertController(title: "", message: String(status), preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
//                NSLog("The \"OK\" alert occured.")
//            }))
//            self.present(alert, animated: true, completion: nil)
            print("\n\n\(status)\n\n")

            CommonDefaults.defaults.set("", forKey: "user-id")
//            CommonDefaults.defaults.set("", forKey: "username")
//            CommonDefaults.defaults.set("", forKey: "password")
            CommonDefaults.showLogin(navController: self.navigationController!, animated: true)
        } catch {
            fatalError()
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
