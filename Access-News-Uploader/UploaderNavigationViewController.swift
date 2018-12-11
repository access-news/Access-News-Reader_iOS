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

        /* 2 `if` cases because:

           1. Userdefaults shows that user signed in to containing app
                 AND
              No one is signed in the current share extension instance
              SO
                sign the user in automatically using their credentials
                from the keychain.

           2. User not signed in the containing app
              SO
                redirect them to the login page.
        */
        if CommonDefaults.isUserLoggedIn() == true && Auth.auth().currentUser == nil {

            let query: [String: Any] =
                [ kSecClass as String:           kSecClassGenericPassword
                , kSecAttrGeneric as String:     CommonDefaults.userID()
                , kSecAttrAccessGroup as String: "K6BD7WSV5V.org.societyfortheblind.Access-News-Reader-kg"
                , kSecReturnAttributes as String: true
                , kSecReturnData as String:       true
                ]

            enum KeychainError: Error {
                case noPassword
                case unexpectedPasswordData
                case unhandledError(status: OSStatus)
            }

            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
//            guard status != errSecItemNotFound
//                else { throw KeychainError.noPassword }
//            guard status == errSecSuccess
//                else { throw KeychainError.unhandledError(status: status) }
            print("\n\n\(status)\n\n")

//            guard
            let existingItem = item as! [String : Any]
            let passwordData = existingItem[kSecValueData as String] as! Data
            let password = String(data: passwordData, encoding: String.Encoding.utf8)!
            let account = existingItem[kSecAttrAccount as String] as! String

//            print("\n\n\(account)\n\n")
//            print("\n\n\(password)\n\n")
//                else {
//                    throw KeychainError.unexpectedPasswordData
//            }
//            let credentials = Credentials(username: account, password: password)

            Auth.auth().signIn(withEmail: account, password: password) {
                (user, error) in

                /* If sign-in is not successful, show log in screen
                   TODO: show error text
                   Otherwise do nothing, and let the nvc load the default
                   root controller.
                */
                if error != nil {
                    print("\n\n\(error!.localizedDescription)\n\n")
                    CommonDefaults.showLogin(navController: self)
                } else {
                    print("\n\nyay?\n\n")
                }
            }
        }

        if CommonDefaults.isUserLoggedIn() == false {
            CommonDefaults.showLogin(navController: self)
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
