//
//  ViewController.swift
//  Access News
//
//  Created by Attila Gulyas on 5/30/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var signInButton: UIButton!
    @IBAction func tapSignInButton(_ sender: Any) {
        
        if (self.username.text == "") {
            self.username.placeholder = "Username missing"
            self.username.becomeFirstResponder()
        } else if (self.password.text == "") {
            self.password.placeholder = "Password missing"
            self.password.becomeFirstResponder()
        }
        
        Auth.auth().signIn(withEmail: username.text!, password: password.text!) {
            (user, error) in
            if error != nil {
                
            } else {
                print(error?.localizedDescription)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.username.delegate = self
        self.password.delegate = self
        
        self.username.clearButtonMode = .always
        self.password.clearButtonMode = .always
        
        self.username.becomeFirstResponder()
        
        self.username.keyboardType = .emailAddress
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
