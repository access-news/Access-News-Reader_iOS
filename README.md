This documentation reflects the status at the time of commit [ef8eb52207b8ff7856fadc5c03a5e8097929630e](https://github.com/society-for-the-blind/Access-News-Reader_iOS/commit/ef8eb52207b8ff7856fadc5c03a5e8097929630e).

# 0. Setup basics

Firebase added via CocoaPods ([guide](https://firebase.google.com/docs/ios/setup)), see `Podfile` for included modules.

Omitting `GoogleService-Info.plist` from the repo this time, but can be generated following the [Firebase iOS guide](https://firebase.google.com/docs/ios/setup) or downloaded from the Firebase console ([steps](https://support.google.com/firebase/answer/7015592)).

## 0.1 Side note

Used some big words regarding using CocoaPods with Firebase in the [abandon notice for Access News Reader](https://github.com/society-for-the-blind/Access-News-Reader-iOS), but after trying to link it statically, it was an even bigger mess. A couple examples after trying for hours:

+ [`libz.dylib` and `libsqlite3.dylib` is missing](https://github.com/firebase/quickstart-ios/issues/247),

+ but linking them from /usr/lib yields "_URGENT: building for iOS simulator, but linking against dylib built for osx. This will be an error in the future._" At the time of this writing the most promising solution seems to be recompiling everything from scratch (see first comment under [Stackoverflow question](https://stackoverflow.com/questions/23092201/ld-building-for-ios-simulator-but-linking-against-dylib#comment-35296130)).

There's still at least 7 more cryptic linking issues.

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

## 2.2 Why not maintain a global timer initialized in `AppDelegate`?

To maintain a global timer would increase the complexity of the app and place a lot of guesswork into the logic as well.

  + Which state transitions would require pausing the timer?<sup>2a</sup>

    

  + 

To make it it explicit delegating to user which is going to require discipline on the reader's part.

<sup>
<div>
  <b>2a</b>) About iOS states and state transitions:
  <ul>
    <li> [Introduction to Backgrounding in iOS](https://docs.microsoft.com/en-us/xamarin/ios/app-fundamentals/backgrounding/introduction-to-backgrounding-in-ios)</li>
    <li> [UIApplicationDelegate protocol documentation](https://developer.apple.com/documentation/uikit/uiapplicationdelegate)</li>
  </ul>
</div>

</sup>
## 2.3 Imagined workflow

The reader signs it, taps "Start Session" button and the session timer starts in the middle of the navigation bar at the top. After recording and submitting (n <= 0) articles the reader can hit "End Session" if they feel that they are finished, automatically submitting and resetting the session timer.

<sup>**TODO**: _Implement session timer submission. (On tapping "End Session"? Or after every article submission? Or periodically after every minute?)_</sup>

# 3. Recording UI (`RecordViewController`)


