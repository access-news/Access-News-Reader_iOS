//
//  ResetPasswordViewController.swift
//  Access News
//
//  Created by Attila Gulyas on 9/11/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

import UIKit
import FirebaseAuth

// https://stackoverflow.com/questions/16230700/display-uiviewcontroller-as-popup-in-iphone

class ResetPasswordViewController: UIViewController {

    @IBOutlet weak var cancelButton: UIButton!
    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBOutlet weak var resetButton: UIButton!
    @IBAction func resetButtonTapped(_ sender: Any) {

        Commands.auth.sendPasswordReset(withEmail: self.emailField.text!) {

            error in

            if error != nil {

                // https://stackoverflow.com/a/37902747/1498178
                if let errCode = AuthErrorCode(rawValue: error!._code) {

                    var errText = ""

                    switch errCode {
                    case .invalidRecipientEmail:
                        errText = "Incorrect email address."
                    case .invalidSender:
                        errText = "Invalid email address."
                    default:
                        errText = error!.localizedDescription
                    }

                    errText += "\n Please try again!"
                    self.errorText.text = errText
                    self.errorText.isHidden = false
                    self.yourEmailLabel.isHidden = true

                    self.emailField.becomeFirstResponder()
                }
            } else {
                self.errorText.isHidden = true
                self.yourEmailLabel.isHidden = false

                let loginVC = self.presentingViewController as?  LoginViewController

                if loginVC != nil {
                    loginVC!.signInError.text = "Email sent!"
                    loginVC!.signInError.textColor = UIColor(red: 0.238, green: 0.753, blue: 0.323, alpha: 1.0)
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }

    @IBOutlet weak var yourEmailLabel: UILabel!
    @IBOutlet weak var errorText: UITextView!

    @IBOutlet weak var emailField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.emailField.delegate = self
        self.emailField.clearButtonMode = .always
        self.emailField.keyboardType = .emailAddress
        self.emailField.autocorrectionType = .no
        self.emailField.spellCheckingType = .no
        self.emailField.becomeFirstResponder()

        self.errorText.isEditable = false
        self.errorText.isHidden = true

        // Do any additional setup after loading the view.
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

extension ResetPasswordViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.resetButtonTapped(self)
    }
}
