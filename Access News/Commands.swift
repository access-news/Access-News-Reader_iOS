//
//  Commands.swift
//  Access News
//
//  Created by Attila Gulyas on 8/29/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

import UIKit
import Firebase

struct Commands {

    static let db = Database.database()
    static let auth = Auth.auth()
    static let user_id = Auth.auth().currentUser!.uid

    static var seq: Int!

    static let commandsGroup = DispatchGroup()

    /* Invoked in SessionStartViewController because it is certain
       at that point that a user is logged in.
    */
    static func seqUpdater() {

        commandsGroup.enter()

        let stateStoreRef =
            self.db.reference().child("/state_store/\(self.user_id)")

        stateStoreRef.observeSingleEvent(of: .value, with: {

            snapshot in

            // https://stackoverflow.com/questions/39623524/swift-firebase-access-child-snapshot-data
            if let childSnapshot = snapshot.childSnapshot(forPath: "seq") as? DataSnapshot {
                self.seq = childSnapshot.value! as! Int
                commandsGroup.leave()
            }
        })
    }

    func startSession() {

        
    }
}
