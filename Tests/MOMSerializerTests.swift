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
        return NSURL(fileURLWithPath: NSTemporaryDirectory().stringByAppendingPathComponent(fileName))!
    }

    func temporaryURLForString(string : String, filename : String) -> NSURL {
        let  temporaryURL = temporaryFileURL("out.xml")
        string.writeToURL(temporaryURL, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
        return temporaryURL
    }

    func xmllint(xmlString : String, options : String) -> String {
        let temporaryURL = temporaryURLForString(xmlString, filename: "out.xml")

        let result = $(NSString(format: "xmllint %@ %@", options, temporaryURL.path!))
        XCTAssertNotEqual("", result, "xmllint failed")

        NSFileManager().removeItemAtURL(temporaryURL, error: nil)
        return result
    }

    func canonicalizeXML(xmlString : String) -> String {
        var result = xmllint(xmlString, options: "--c14n")
        return xmllint(result, options: "--format")
    }

    func diff(oneString : String, anotherString: String) {
        let temporaryURL1 = temporaryURLForString(oneString, filename: "1.xml")
        let temporaryURL2 = temporaryURLForString(anotherString, filename: "2.xml")

        let result = $(NSString(format: "diff -w %@ %@", temporaryURL1.path!, temporaryURL2.path!))
        XCTAssertEqual(result, "", "")

        NSFileManager().removeItemAtURL(temporaryURL1, error: nil)
        NSFileManager().removeItemAtURL(temporaryURL2, error: nil)
    }

    func compareXML(xmlString : String, withXMLAtPath : String) {
        var compareXML = NSString(contentsOfFile: withXMLAtPath, encoding: NSUTF8StringEncoding, error: nil)!
        compareXML = canonicalizeXML(compareXML)

        diff(canonicalizeXML(xmlString), anotherString: compareXML)
    }
    
    func testEmpty() {
        let model = NSManagedObjectModel()
        let expected = "<?xml version=\"1.0\" encoding=\"utf8\"?><model lastSavedToolsVersion=\"6244\" iOSVersion=\"Automatic\" minimumToolsVersion=\"Automatic\" userDefinedModelVersionIdentifier=\"\" documentVersion=\"1.0\" macOSVersion=\"Automatic\" systemVersion=\"14A361c\" type=\"com.apple.IDECoreDataModeler.DataModel\"><elements/></model>"

        let momXML = ModelSerializer(model: model).generate().toString(encoding: "utf8")

        XCTAssertEqual(expected, momXML, "")
    }

    func testComplex() {
        let url = NSBundle(forClass: self.dynamicType).URLForResource("CoreDataExample", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOfURL: url!)
        XCTAssertNotNil(model, "")

        let momXML = ModelSerializer(model: model!).generate().toString(encoding: "utf8")

        let path = NSBundle(forClass: self.dynamicType).pathForResource("complex-test", ofType: "xml")
        compareXML(momXML, withXMLAtPath: path!)
    }

    func testPlist() {
        let plistXML = ModelSerializer(model: NSManagedObjectModel()).generateCurrentVersionPlist("CoreDataExample").toString(encoding: "utf8")

        let path = NSBundle(forClass: self.dynamicType).pathForResource("plist-test", ofType: "xml")
        compareXML(plistXML, withXMLAtPath: path!)
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
        println($(NSString(format: "xcrun momc %@ %@", modelURL.path!, outputURL.path!)))

        let outputModel = NSManagedObjectModel(contentsOfURL: outputURL)
        XCTAssertNotNil(outputModel, "")

        NSFileManager().removeItemAtURL(modelURL, error: nil)
        NSFileManager().removeItemAtURL(outputURL, error: nil)
    }
    
}
