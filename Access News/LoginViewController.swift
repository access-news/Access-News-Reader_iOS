//
//  ViewController.swift
//  Access News
//
//  Created by Attila Gulyas on 5/30/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    let auth = Auth.auth()

    @IBOutlet weak var signInError: UILabel!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!

    @IBOutlet weak var forgotPassword: UIButton!

    @IBOutlet weak var signInButton: UIButton!
    @IBAction func tapSignInButton(_ sender: Any) {

        if (self.username.text == "") {
            self.username.placeholder = "Username missing"
            self.username.becomeFirstResponder()
        } else if (self.password.text == "") {
            self.password.placeholder = "Password missing"
            self.password.becomeFirstResponder()
        } else {
            self.auth.signIn(withEmail: self.username.text!, password: self.password.text!) {
                (user, error) in
                if error != nil {
                    let errorCode = AuthErrorCode(rawValue: (error! as NSError).code)!

                    // https://stackoverflow.com/questions/37449919/reading-firebase-auth-error-thrown-firebase-3-x-and-swift
                    switch errorCode {
                        case .userNotFound:
                            self.signInError.text = "Incorrect email or password."
                        case .wrongPassword:
                            self.signInError.text = "Incorrect email or password."
                        default:
                            self.signInError.text = error?.localizedDescription
                    }
                } else {

                    /* Adding credentials to the keychain and sharing it
                       https://developer.apple.com/documentation/security/keychain_services/keychain_items/adding_a_password_to_the_keychain
                       https://stackoverflow.com/questions/44387242/keychain-sharing-between-two-apps

                       Abandoned this idea briefly, because error -34018 (errSecMissingEntitlement)
                       kept popping up no matter what, and whatever info I found was about dubious
                       fixes, and mostly that this is a bug that hasn't been fixed. The only option
                       left was to use `Userdefaults` for storing the credentials, but that would
                       have been unsafe.

                       Errors: (almost useless though)
                       https://developer.apple.com/documentation/security/1542001-security_framework_result_codes?language=objc

                       Fortunately found the below github issue, and the solution was adding the
                       app prefix as described in the linked comment.
                       https://github.com/jrendel/SwiftKeychainWrapper/issues/78#issuecomment-424960801
                       So instead of
                                      "org.societyfortheblind.Access-News-Reader-kg"
                       use
                           "K6BD7WSV5V.org.societyfortheblind.Access-News-Reader-kg"
                       and then just follow the guides.

                       Some links for posterity:

                       + https://developer.apple.com/documentation/security/ksecvaluedata
                         (linking because it is not in the place where one would expect)
                       + https://developer.apple.com/documentation/security/keychain_services/keychain_items/item_return_result_keys
                       + https://developer.apple.com/documentation/security/keychain_services/keychain_items/adding_a_password_to_the_keychain
                       + https://developer.apple.com/documentation/security/keychain_services/keychain_items/searching_for_keychain_items
                       + https://developer.apple.com/documentation/security/keychain_services/keychain_items/item_class_keys_and_values
                       + https://developer.apple.com/documentation/security/keychain_services/keychain_items/item_attribute_keys_and_values
                    */

                    /* NOTE ON SHARING firebase project BETWEEN CONTAINING APP AND SHARE EXTENSION

                       No clue what the official solution, and most sources say that
                       an extra app should be created, blabla. Probably, but right
                       now the main "GoogleService-Info.plist" is copied into the
                       share extension as well, with the BUNDLE_ID changed
                       from the containing app's id
                          ("org.societyfortheblind.Access-News")
                       to the share extension one
                          ("org.societyfortheblind.Access-News-Reader.Access-News-Uploader").

                       With that said, the "uploader" app is still present in the
                       Firebase project (see console), and probably won't dare to
                       delete it (even though unused) until Firebase is abandoned
                       completely.
                    */

//                    enum KeychainError: Error {
//                        case noPassword
//                        case unexpectedPasswordData
//                        case unhandledError(status: OSStatus)
//                    }

                    if CommonDefaults.isUserLoggedIn() == false {
                        let addQuery: [String: Any] =
                            [ kSecClass as String:           kSecClassGenericPassword
                            , kSecAttrAccount as String:     self.username.text!
                            , kSecValueData as String:       self.password.text!.data(using: String.Encoding.utf8)!
                            , kSecAttrGeneric as String:     self.auth.currentUser!.uid
                            , kSecAttrAccessGroup as String: "K6BD7WSV5V.org.societyfortheblind.Access-News-Reader-kg"
                            ]

                        let status = SecItemAdd(addQuery as CFDictionary, nil)
                        print("\n\n\(status)\n\n")

                        CommonDefaults.defaults.set(Auth.auth().currentUser?.uid, forKey: "user-id")
//                        CommonDefaults.defaults.set(self.username.text!, forKey: "username")
//                        CommonDefaults.defaults.set(self.password.text!, forKey: "password")
                    }

//                    let alert = UIAlertController(title: "", message: String(status), preferredStyle: .alert)
//                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
//                        NSLog("The \"OK\" alert occured.")
//                    }))
//                    self.present(alert, animated: true, completion: nil)
//                    guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status)}

                    // Still not perfect, but at least now LoginViewController only
                    // assumes that it is included in a navigation controller.
                    self.navigationController?.popViewController(animated: false)
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.password.delegate = self
        self.password.clearButtonMode = .always
        self.password.isSecureTextEntry = true
        
        self.username.delegate = self
        self.username.clearButtonMode = .always
        self.username.keyboardType = .emailAddress
        self.username.autocorrectionType = .no
        self.username.spellCheckingType = .no

        self.username.becomeFirstResponder()

        self.signInError.textColor = .red

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension LoginViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {

        /* https://developer.apple.com/library/content/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/ManageTextFieldTextViews/ManageTextFieldTextViews.html#//apple_ref/doc/uid/TP40009542-CH10-SW17
           Another solution could have been to create new separate classes as delegates,
           but this works.
        */
        switch textField {
            case self.username:
                password.becomeFirstResponder()
            case self.password:
                self.tapSignInButton(self)
            default:
                break
        }
    }
}
