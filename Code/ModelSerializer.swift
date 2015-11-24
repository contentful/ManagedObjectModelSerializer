//
//  ModelSerializer.swift
//  ManagedObjectModelSerializer
//
//  Created by Boris Bügling on 31/10/14.
//  Copyright (c) 2014 Boris Bügling. All rights reserved.
//

import CoreData

public class ModelSerializer {
    let model : NSManagedObjectModel

    public init(model : NSManagedObjectModel) {
        self.model = model
    }

    func document() -> XMLElement {
        return </"model" | ["userDefinedModelVersionIdentifier": ""] | ["type": "com.apple.IDECoreDataModeler.DataModel"] | ["documentVersion": "1.0"] | ["lastSavedToolsVersion": "6244"] | ["systemVersion": "14A361c"] | ["minimumToolsVersion": "Automatic"] | ["macOSVersion": "Automatic"] | ["iOSVersion": "Automatic"] |
            entities() |
            elements()
    }

    func entities() -> [XMLNode] {
        return (model.entities.sort({ (entity1, entity2) -> Bool in
            return entity1.name < entity2.name
            }) ).map({ EntitySerializer(entity: $0).generate() })
    }

    func elements() -> XMLElement {
        var elements : [XMLNode] = []

        for entityObject in model.entities.sort({ (entity1, entity2) -> Bool in
            return entity1.name < entity2.name
        }) {
            let entity = entityObject 
            elements.append(</"element" | ["name": entity.name!] | ["positionX": "0"] | ["positionY": "0"] | ["width": "0"] | ["height": "0"])
        }

        return </"elements" | elements
    }

    public func generate() -> XMLDocument {
        return XML(document())
    }

    public func generateCurrentVersionPlist(name : String) -> XMLDocument {
        let doctype = Doctype(publicID: "-//Apple//DTD PLIST 1.0//EN", systemID: "http://www.apple.com/DTDs/PropertyList-1.0.dtd")
        return XML(</"plist" |
            [</"dict" |
                [
                    </"key" | <&"_XCCurrentVersionName",
                    </"string" | <&(name + ".xcdatamodel")
                ]
            ], doctype: doctype)
    }

    public func generateBundle(name : String, atPath: NSURL) throws {
        let modeldPath = atPath.URLByAppendingPathComponent(name + ".xcdatamodeld")

        var actualName = name
        if NSFileManager.defaultManager().fileExistsAtPath(modeldPath.path!) {
            actualName = name + String(format:" %i", lastVersion(modeldPath) + 1)
        }

        let modelPath = modeldPath.URLByAppendingPathComponent(actualName + ".xcdatamodel")
        let currentVersionPath = modeldPath.URLByAppendingPathComponent(".xccurrentversion")
        let actualModelPath = modelPath.URLByAppendingPathComponent("contents")

        try NSFileManager().createDirectoryAtURL(modelPath, withIntermediateDirectories: true, attributes: nil)
        try generateCurrentVersionPlist(actualName).toString("utf8").writeToURL(currentVersionPath, atomically: true, encoding: NSUTF8StringEncoding)
        try generate().toString("utf8").writeToURL(actualModelPath, atomically: true, encoding: NSUTF8StringEncoding)
    }

    func lastVersion(modeldPath: NSURL) -> Int {
        let files = try? NSFileManager.defaultManager().contentsOfDirectoryAtURL(modeldPath, includingPropertiesForKeys: nil, options: .SkipsSubdirectoryDescendants)

        var lastVersion = 1

        if let files = files {
            for file in files {
                if let path = file.URLByDeletingPathExtension?.path, last = path.componentsSeparatedByString(" ").last, version = Int(last) {
                    lastVersion = version > lastVersion ? version : lastVersion
                }
            }
        }

        return lastVersion
    }
}
