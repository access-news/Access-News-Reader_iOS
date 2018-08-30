//
//  SessionStartViewController.swift
//  Access News
//
//  Created by Attila Gulyas on 7/3/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

import UIKit
import Firebase

class SessionStartViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        Commands.seqUpdater()

        self.navigationItem.rightBarButtonItem =
            UIBarButtonItem(title:  "Sign out",
                            style:  .plain,
                            target: self,
                            action: #selector(signOutTapped))
    }

    @objc func signOutTapped() {
        do {
            try Auth.auth().signOut()

            let storyboard = UIStoryboard(name: "Main", bundle: .main)
            let login = storyboard.instantiateInitialViewController()!
            self.present(login, animated: true, completion: nil)
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
