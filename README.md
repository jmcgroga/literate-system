# NetHack Swift Bridge

Bridging Swift to NetHack

- Implement SwiftNetHack Protocol
- Add the startup code:
```swift
setNetHack(YourSwiftNetHackClassHere())
var cargs = CommandLine.arguments.map { UnsafeMutablePointer<Int8>(strdup($0)) }
my_main(CommandLine.argc, &cargs)
```
