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

    let defaults = UserDefaults.init(suiteName: "group.org.societyfortheblind.access-news-reader-ag")!

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
            Auth.auth().signIn(withEmail: username.text!, password: password.text!) {
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
                    self.defaults.set(true, forKey: "user-logged-in")
                    let storyboard = UIStoryboard(name: "Main", bundle: .main)
                    let nvc = storyboard.instantiateViewController(withIdentifier: "NVC")
                    self.present(nvc, animated: true, completion: nil)
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
