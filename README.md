This documentation reflects the status at the time of commit [ef8eb52207b8ff7856fadc5c03a5e8097929630e](https://github.com/society-for-the-blind/Access-News-Reader_iOS/commit/ef8eb52207b8ff7856fadc5c03a5e8097929630e).

# 0. Setup basics

Firebase added via CocoaPods ([guide](https://firebase.google.com/docs/ios/setup)), see `Podfile` for included modules.<sup id="note-0-up"><a href="#user-content-note-0-bottom">[0]</a></sup>

Omitting `GoogleService-Info.plist` from the repo this time, but can be generated following the [Firebase iOS guide](https://firebase.google.com/docs/ios/setup) or downloaded from the Firebase console ([steps](https://support.google.com/firebase/answer/7015592)).

# 1. Login and persisting the user

`LoginViewController` is set up as initial view controller in `Main.storyboard`, and if the user was able to sign in then they are redirected to the main navigation controller (also defined in the `Main.storyboard` only with ID "NVC").

The `AppDelegate` checks Firebase's default auth object for a signed in user (`Auth.auth().currentUser`; `FIRAuth` in Objective-C), and loads the main navigation controller directly ("NVC"), bypassing `LoginViewController`.

<sup>**TODO**: _Implement password reset (see #2)_</sup>

# 2. `SessionStartViewController`

"NVC"'s root view controller, shown right after login.

## 2.1 Rationale

Volunteer hours are required to be reported to our grantor, the California State Library, and important fact is that the length of a recording session is not the same as the sum of the lengths of submitted recordings. For example, one needs time to prepare, set up the recording environment, etc.

The main recording UI is already heavily packed and just adding an intermediate view controller seemed like the best (and easiest) solution to maintain a timer distinct from the playback and recording timer.

<sup>**TODO**: _Add user statistics under the single button that currently occupies `SessionStartViewController`_.</sup>

## 2.2 Why not use `AppDelegate` to set up a global timer to make session management implicit, without the need of user interaction?

This would increase the complexity of the app and place a lot of guesswork into the logic as well:

  + Which state transitions would require pausing the timer?<sup id="note-1-up"><a href="#user-content-note-1-bottom">[1]</a></sup>

  + When app is in the "inactive" state (i.e., foreground, but not receiving any events), should timer be paused? The reader could be rehearsing, for example.


Making session management the users' responsibility avoids the above issues and puts more control into the hand of the volunteers<sup id="note-2-up"><a href="#user-content-note-2-bottom">[2]</a></sup>.

## 2.3 Example workflow

The reader signs in, taps "Start Session" button, signaling that they are starting volunteering for Access news. The session timer, in the middle of the navigation bar at the top, starts ticking.

The user gets ready to record (practice, set up equipment, browse articles/publications, etc.).

Once ready, the reader taps the "Record" button to start the recording process, and control their progress using the other buttons on the user interface (such as "Pause", "Start Over" etc.).

Once they are finished with an article, hitting the "Submit" button will upload the content to the Access News service.

After recording and submitting (n <= 0) articles the reader can hit "End Session" if they feel that they are finished, automatically submitting the session timer.

<sup>**TODO**: _Implement session timer submission. (On tapping "End Session"? Or after every article submission? Or periodically after every minute?)_</sup>

# 3. Recording UI (`RecordViewController`)



0) <a id="note-0-bottom" href="#user-content-note-0-up">[^]</a> Used some big words regarding using CocoaPods with Firebase in the [abandon notice for Access News Reader](https://github.com/society-for-the-blind/Access-News-Reader-iOS), but after trying to link it statically, it was an even bigger mess. A couple examples after trying for hours:

+ [`libz.dylib` and `libsqlite3.dylib` is missing](https://github.com/firebase/quickstart-ios/issues/247),

+ but linking them from /usr/lib yields "_URGENT: building for iOS simulator, but linking against dylib built for osx. This will be an error in the future._" At the time of this writing the most promising solution seems to be recompiling everything from scratch (see first comment under [Stackoverflow question](https://stackoverflow.com/questions/23092201/ld-building-for-ios-simulator-but-linking-against-dylib#comment-35296130)).

There's still at least 7 more cryptic linking issues.

1) <a id="note-1-bottom" href="#user-content-note-1-up">[^]</a> About iOS states and state transitions:

  + [Introduction to Backgrounding in iOS](https://docs.microsoft.com/en-us/xamarin/ios/app-fundamentals/backgrounding/introduction-to-backgrounding-in-ios)

  + [UIApplicationDelegate protocol documentation](https://developer.apple.com/documentation/uikit/uiapplicationdelegate)

2) <a id="note-2-bottom" href="#user-content-note-2-up">[^]</a> One use case when this comes in handy is tracking community service hours.
