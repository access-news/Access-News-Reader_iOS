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

//    static let db = Database.database()
    static let dbref = Database.database().reference()
    static let auth = Auth.auth()
    static let user_id = Auth.auth().currentUser!.uid

    static var seq: Int!

    static let commandsGroup = DispatchGroup()

    /* Invoked in SessionStartViewController because it is certain
       at that point that a user is logged in.
    */
    static func seqUpdater() {

        let stateStoreRef =
            self.dbref.child("/state_store/\(self.user_id)")

        stateStoreRef.observe(.value) {

            snapshot in

            commandsGroup.enter()

            // https://stackoverflow.com/questions/39623524/swift-firebase-access-child-snapshot-data
            let childSnapshot = snapshot.childSnapshot(forPath: "seq")
            self.seq = childSnapshot.value! as! Int
            commandsGroup.leave()
        }
    }

    static var session_id = ""

    static func startSession() {

        self.session_id =
            self.dispatchEvent(
            aggregate:  "people",
            event_name: "session_started",
            payload:    ["seconds": 0],
            stream_id:  self.user_id
        )
    }

    static func updateSession(seconds: Int, done: Bool = false) {
        
        _ = self.dispatchEvent(
                aggregate:  "people",
                event_name: "session_started",
                payload:
                    [ "seconds":  seconds
                    , "event_id": self.session_id
                    ],
                stream_id:  self.user_id
        )

        if  done == true {
            self.session_id = ""
        }
    }

    static func addRecording(publication: String, title: String) {

        _ =
            self.dispatchEvent(
                aggregate: "people",
                event_name: "recording_added",
                payload:
                    [ "publication": publication
                    , "title": title
                    ],
                stream_id: self.user_id
        )
    }

    static func dispatchEvent(
        aggregate:  String,
        event_name: String,
        payload:    [String: Any],
        stream_id:  String
    ) -> String {
        let event: [String: Any] =
            [ "aggregate":  aggregate
            , "event_name": event_name
            , "fields":     payload
            , "seq":        self.seq + 1
            , "stream_id":  stream_id
            , "version":    0
            , "timestamp":  ServerValue.timestamp()
            ]

        let pushRef = self.dbref.child("/event_store").childByAutoId()

        commandsGroup.notify(queue: .main) {
            pushRef.setValue(event)
        }

        return pushRef.key
    }
}
