# ManagedObjectModelSerializer

A framework for serializing an in-memory `NSManagedObjectModel`
into the same XML format Xcode generates when using the built-in
CoreData modelling tools.

MOMSerializer is written in Swift and requires Xcode 7.1 to compile.
It uses [ECoXiS][1] for the XML serialization and [SwiftShell][2] for
launching some CLI utilities as part of the testsuite.

## Usage

```swift
let bundleName = "MyModel"
let model: NSManagedObjectModel
let pathURL: NSURL

try ModelSerializer(model: model!).generateBundle(bundleName, atPath:pathURL)
```

This will generate a `MyModel.xcdatamodeld` bundle with one model version,
generated from the given in-memory `NSManagedObjectModel` at the given path.

## License

Copyright (c) 2014 Contentful GmbH. See LICENSE for further details.

[1]: https://github.com/IvIePhisto/ECoXiS 
[2]: https://github.com/kareman/SwiftShell
