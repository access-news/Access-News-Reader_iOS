//
//  EmbeddedViewController.swift
//  Access News Uploader share extension
//
//  Created by Attila Gulyas on 10/30/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

import UIKit

class EmbeddedViewController: UIViewController {

    @IBOutlet weak var publicationDropDown: DropDown!
    @IBOutlet weak var volunteerTimeDropDown: DropDown!
    @IBOutlet weak var volunteerTimeNote: UITextView!

    @IBOutlet weak var submitBarButton: UIBarButtonItem!
    @IBAction func submitTapped(_ sender: Any) {
        print("lfoa")
    }

    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    @IBAction func cancelTapped(_ sender: Any) {
        // https://stackoverflow.com/questions/43670938/dismiss-share-extension-custom-viewcontroller
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        volunteerTimeNote.isEditable = false
        volunteerTimeNote.isSelectable = false

        self.navigationController?.navigationBar.layer.cornerRadius = 19
        self.navigationController?.navigationBar.clipsToBounds = true

        self.volunteerTimeDropDown.optionArray =
            Array(1...250)
                .filter { $0 % 5 == 0 }
                .map { "\($0 / 60) h \($0 % 60) min" }

        self.publicationDropDown.optionArray =
            CommonDefaults.publications
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
