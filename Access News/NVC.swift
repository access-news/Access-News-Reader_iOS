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

    override func viewDidLoad() {
        super.viewDidLoad()

        CommonDefaults.showLoginIfNoUser(navController: self)
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
