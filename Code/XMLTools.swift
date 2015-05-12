//
//  XMLTools.swift
//  ManagedObjectModelSerializer
//
//  Created by Boris Bügling on 11/11/14.
//  Copyright (c) 2014 Boris Bügling. All rights reserved.
//

import Foundation

func temporaryFileURL(filename : String) -> NSURL {
    let fileName = NSString(format: "%@_%@", NSProcessInfo.processInfo().globallyUniqueString, filename)
    return NSURL(fileURLWithPath: NSTemporaryDirectory().stringByAppendingPathComponent(fileName as String))!
}

func temporaryURLForString(string : String, filename : String) -> NSURL {
    let  temporaryURL = temporaryFileURL("out.xml")
    string.writeToURL(temporaryURL, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
    return temporaryURL
}

func xmllint(xmlString : String, options : String) -> String {
    let temporaryURL = temporaryURLForString(xmlString, "out.xml")
    let result = $(NSString(format: "xmllint %@ %@", options, temporaryURL.path!) as String)

    NSFileManager().removeItemAtURL(temporaryURL, error: nil)
    return result
}

func canonicalizeXML(xmlString : String) -> String {
    var result = xmllint(xmlString, "--c14n")
    return xmllint(result, "--format")
}

func diff(oneString : String, anotherString: String) -> String {
    let temporaryURL1 = temporaryURLForString(oneString, "1.xml")
    let temporaryURL2 = temporaryURLForString(anotherString, "2.xml")

    let result = $(NSString(format: "diff -w %@ %@", temporaryURL1.path!, temporaryURL2.path!) as String)

    NSFileManager().removeItemAtURL(temporaryURL1, error: nil)
    NSFileManager().removeItemAtURL(temporaryURL2, error: nil)

    return result
}

public class XMLTools {
    public class func compareXML(xmlString : String, withXMLAtPath : String) -> String {
        var compareXML = NSString(contentsOfFile: withXMLAtPath, encoding: NSUTF8StringEncoding, error: nil)!
        compareXML = canonicalizeXML(compareXML as String)

        return diff(canonicalizeXML(xmlString), compareXML as String)
    }
}
