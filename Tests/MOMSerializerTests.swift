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
        return NSURL(fileURLWithPath: NSTemporaryDirectory().stringByAppendingPathComponent(fileName as String))!
    }

    func temporaryURLForString(string : String, filename : String) -> NSURL {
        let  temporaryURL = temporaryFileURL("out.xml")
        string.writeToURL(temporaryURL, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
        return temporaryURL
    }

    func testEmpty() {
        let model = NSManagedObjectModel()
        let expected = "<?xml version=\"1.0\" encoding=\"utf8\"?><model lastSavedToolsVersion=\"6244\" iOSVersion=\"Automatic\" minimumToolsVersion=\"Automatic\" userDefinedModelVersionIdentifier=\"\" documentVersion=\"1.0\" macOSVersion=\"Automatic\" systemVersion=\"14A361c\" type=\"com.apple.IDECoreDataModeler.DataModel\"><elements/></model>"

        let momXML = ModelSerializer(model: model).generate().toString(encoding: "utf8")

        XCTAssertEqual(expected, momXML, "")
    }

    func testAllTypes() {
        let url = NSBundle(forClass: self.dynamicType).URLForResource("AllTypes", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOfURL: url!)
        XCTAssertNotNil(model, "")

        let momXML = ModelSerializer(model: model!).generate().toString(encoding: "utf8")

        let path = NSBundle(forClass: self.dynamicType).pathForResource("alltypes-test", ofType: "xml")
        XCTAssertEqual("", XMLTools.compareXML(momXML, withXMLAtPath: path!), "")
    }

    func testComplex() {
        let url = NSBundle(forClass: self.dynamicType).URLForResource("CoreDataExample", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOfURL: url!)
        XCTAssertNotNil(model, "")

        let momXML = ModelSerializer(model: model!).generate().toString(encoding: "utf8")

        let path = NSBundle(forClass: self.dynamicType).pathForResource("complex-test", ofType: "xml")
        XCTAssertEqual("", XMLTools.compareXML(momXML, withXMLAtPath: path!), "")
    }

    func testPlist() {
        let plistXML = ModelSerializer(model: NSManagedObjectModel()).generateCurrentVersionPlist("CoreDataExample").toString(encoding: "utf8")

        let path = NSBundle(forClass: self.dynamicType).pathForResource("plist-test", ofType: "xml")
        XCTAssertEqual("", XMLTools.compareXML(plistXML, withXMLAtPath: path!), "")
    }

    func testCanBeLoaded() {
        let url = NSBundle(forClass: self.dynamicType).URLForResource("CoreDataExample", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOfURL: url!)
        XCTAssertNotNil(model, "")

        let tempPathURL = temporaryFileURL("").URLByDeletingLastPathComponent!
        let error = ModelSerializer(model: model!).generateBundle("Test", atPath:tempPathURL)
        XCTAssertNil(error)

        let modelURL = tempPathURL.URLByAppendingPathComponent("Test.xcdatamodeld")
        let outputURL = tempPathURL.URLByAppendingPathComponent("Test.momd")
        println($(NSString(format: "xcrun momc %@ %@", modelURL.path!, outputURL.path!) as String))

        let outputModel = NSManagedObjectModel(contentsOfURL: outputURL)
        XCTAssertNotNil(outputModel, "")

        NSFileManager().removeItemAtURL(modelURL, error: nil)
        NSFileManager().removeItemAtURL(outputURL, error: nil)
    }

    func testNewVersion() {
        let url = NSBundle(forClass: self.dynamicType).URLForResource("CoreDataExample", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOfURL: url!)
        XCTAssertNotNil(model, "")

        let tempPathURL = temporaryFileURL("").URLByDeletingLastPathComponent!

        for i in 0...4 {
            let error = ModelSerializer(model: model!).generateBundle("Test", atPath:tempPathURL)
            XCTAssertNil(error)
        }
        let modelURL = tempPathURL.URLByAppendingPathComponent("Test.xcdatamodeld")

        let urls = NSFileManager.defaultManager().contentsOfDirectoryAtURL(modelURL, includingPropertiesForKeys: nil, options: .SkipsHiddenFiles, error: nil) as! [NSURL]?

        if let urls = urls {
            let names = urls.map({ (url) -> String in return (url.lastPathComponent)! })
            XCTAssertEqual([ "Test 2.xcdatamodel", "Test 3.xcdatamodel", "Test 4.xcdatamodel", "Test 5.xcdatamodel", "Test.xcdatamodel" ], names, "")
        } else {
            XCTFail("Could not list URLs of Core Data model.")
        }

        let currentVersion = NSString(contentsOfURL: modelURL.URLByAppendingPathComponent(".xccurrentversion"), encoding: NSUTF8StringEncoding, error: nil)!
        let expectedVersion = ModelSerializer(model: model!).generateCurrentVersionPlist("Test 5").toString(encoding: "utf8") as NSString
        XCTAssertEqual(expectedVersion, currentVersion, "")

        NSFileManager().removeItemAtURL(modelURL, error: nil)
    }
    
}
