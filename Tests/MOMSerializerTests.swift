//
//  MOMSerializerTests.swift
//  MOMSerializerTests
//
//  Created by Boris Bügling on 31/10/14.
//  Copyright (c) 2014 Boris Bügling. All rights reserved.
//

import MOMSerializer
import XCTest

class MOMSerializerTests: XCTestCase {
    func temporaryFileURL(filename : String) -> NSURL {
        let fileName = NSString(format: "%@_%@", NSProcessInfo.processInfo().globallyUniqueString, filename)
        return NSURL(fileURLWithPath: (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(fileName as String))
    }

    func temporaryURLForString(string : String, filename : String) -> NSURL {
        let  temporaryURL = temporaryFileURL("out.xml")
        do {
            try string.writeToURL(temporaryURL, atomically: true, encoding: NSUTF8StringEncoding)
        } catch _ {
        }
        return temporaryURL
    }

    func testEmpty() {
        let model = NSManagedObjectModel()
        let expected = "<?xml version=\"1.0\" encoding=\"utf8\"?><model lastSavedToolsVersion=\"6244\" iOSVersion=\"Automatic\" minimumToolsVersion=\"Automatic\" userDefinedModelVersionIdentifier=\"\" documentVersion=\"1.0\" macOSVersion=\"Automatic\" systemVersion=\"14A361c\" type=\"com.apple.IDECoreDataModeler.DataModel\"><elements/></model>"

        let momXML = ModelSerializer(model: model).generate().toString("utf8")

        XCTAssertEqual(expected, momXML, "")
    }

    func testAllTypes() {
        let url = NSBundle(forClass: self.dynamicType).URLForResource("AllTypes", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOfURL: url!)
        XCTAssertNotNil(model, "")

        let momXML = ModelSerializer(model: model!).generate().toString("utf8")

        let path = NSBundle(forClass: self.dynamicType).pathForResource("alltypes-test", ofType: "xml")
        XCTAssertEqual("", XMLTools.compareXML(momXML, withXMLAtPath: path!), "")
    }

    func testComplex() {
        let url = NSBundle(forClass: self.dynamicType).URLForResource("CoreDataExample", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOfURL: url!)
        XCTAssertNotNil(model, "")

        let momXML = ModelSerializer(model: model!).generate().toString("utf8")

        let path = NSBundle(forClass: self.dynamicType).pathForResource("complex-test", ofType: "xml")
        XCTAssertEqual("", XMLTools.compareXML(momXML, withXMLAtPath: path!), "")
    }

    func testPlist() {
        let plistXML = ModelSerializer(model: NSManagedObjectModel()).generateCurrentVersionPlist("CoreDataExample").toString("utf8")

        let path = NSBundle(forClass: self.dynamicType).pathForResource("plist-test", ofType: "xml")
        XCTAssertEqual("", XMLTools.compareXML(plistXML, withXMLAtPath: path!), "")
    }

    func testCanBeLoaded() {
        let url = NSBundle(forClass: self.dynamicType).URLForResource("CoreDataExample", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOfURL: url!)
        XCTAssertNotNil(model, "")

        let tempPathURL = temporaryFileURL("").URLByDeletingLastPathComponent!
        try! ModelSerializer(model: model!).generateBundle("Test", atPath:tempPathURL)

        let modelURL = tempPathURL.URLByAppendingPathComponent("Test.xcdatamodeld")
        let outputURL = tempPathURL.URLByAppendingPathComponent("Test.momd")
        print($(NSString(format: "xcrun momc %@ %@", modelURL!.path!, outputURL!.path!) as String))

        let outputModel = NSManagedObjectModel(contentsOfURL: outputURL!)
        XCTAssertNotNil(outputModel, "")

        do {
            try NSFileManager().removeItemAtURL(modelURL!)
        } catch _ {
        }
        do {
            try NSFileManager().removeItemAtURL(outputURL!)
        } catch _ {
        }
    }

    func testNewVersion() {
        let url = NSBundle(forClass: self.dynamicType).URLForResource("CoreDataExample", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOfURL: url!)
        XCTAssertNotNil(model, "")

        let tempPathURL = temporaryFileURL("").URLByDeletingLastPathComponent!

        for _ in 0...4 {
            try! ModelSerializer(model: model!).generateBundle("Test", atPath:tempPathURL)
        }
        let modelURL = tempPathURL.URLByAppendingPathComponent("Test.xcdatamodeld")

        let urls = (try? NSFileManager.defaultManager().contentsOfDirectoryAtURL(modelURL!, includingPropertiesForKeys: nil, options: .SkipsHiddenFiles))

        if let urls = urls {
            let names = urls.map({ (url) -> String in return (url.lastPathComponent)! })
            XCTAssertEqual([ "Test 2.xcdatamodel", "Test 3.xcdatamodel", "Test 4.xcdatamodel", "Test 5.xcdatamodel", "Test.xcdatamodel" ], names, "")
        } else {
            XCTFail("Could not list URLs of Core Data model.")
        }

        let currentVersion = try! NSString(contentsOfURL: modelURL!.URLByAppendingPathComponent(".xccurrentversion")!, encoding: NSUTF8StringEncoding)
        let expectedVersion = ModelSerializer(model: model!).generateCurrentVersionPlist("Test 5").toString("utf8") as NSString
        XCTAssertEqual(expectedVersion, currentVersion, "")

        do {
            try NSFileManager().removeItemAtURL(modelURL!)
        } catch _ {
        }
    }
    
}
