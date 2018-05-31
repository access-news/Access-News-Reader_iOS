 + Firebase added via CocoaPods ([guide](https://firebase.google.com/docs/ios/setup)), see `Podfile` for included modules.

 + Omitting `GoogleService-Info.plist` from the repo this time, but can be generated following the [guide](https://firebase.google.com/docs/ios/setup) or downloaded from the Firebase console ([steps](https://support.google.com/firebase/answer/7015592)).

rants
=====

Used some big words regarding using CocoaPods with Firebase in the [abandon notice for Access News Reader](https://github.com/society-for-the-blind/Access-News-Reader-iOS), but after trying to link it statically, it was an even bigger mess. A couple examples after trying for hours:

  + [`libz.dylib` and `libsqlite3.dylib` is missing](https://github.com/firebase/quickstart-ios/issues/247),

  + but linking them from /usr/lib yields "_URGENT: building for iOS simulator, but linking against dylib built for osx. This will be an error in the future._" At the time of this writing the most promising solution seems to be recompiling everything from scratch (see first comment under [Stackoverflow question](https://stackoverflow.com/questions/23092201/ld-building-for-ios-simulator-but-linking-against-dylib#comment-35296130)).

  + There's still at least 7 more cryptic linking issues.

Retrying CocoaPods.

---  


