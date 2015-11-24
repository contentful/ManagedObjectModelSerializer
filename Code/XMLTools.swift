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

func xmllint(xmlString : String, options : String) -> String {
    let temporaryURL = temporaryURLForString(xmlString, filename: "out.xml")
    let result = $(NSString(format: "xmllint %@ %@", options, temporaryURL.path!) as String)

    do {
        try NSFileManager().removeItemAtURL(temporaryURL)
    } catch _ {
    }
    return result
}

func canonicalizeXML(xmlString : String) -> String {
    let result = xmllint(xmlString, options: "--c14n")
    return xmllint(result, options: "--format")
}

func diff(oneString : String, anotherString: String) -> String {
    let temporaryURL1 = temporaryURLForString(oneString, filename: "1.xml")
    let temporaryURL2 = temporaryURLForString(anotherString, filename: "2.xml")

    let result = $(NSString(format: "diff -w %@ %@", temporaryURL1.path!, temporaryURL2.path!) as String)

    do {
        try NSFileManager().removeItemAtURL(temporaryURL1)
    } catch _ {
    }
    do {
        try NSFileManager().removeItemAtURL(temporaryURL2)
    } catch _ {
    }

    return result
}

public class XMLTools {
    public class func compareXML(xmlString : String, withXMLAtPath : String) -> String {
        var compareXML = try! NSString(contentsOfFile: withXMLAtPath, encoding: NSUTF8StringEncoding)
        compareXML = canonicalizeXML(compareXML as String)

        return diff(canonicalizeXML(xmlString), anotherString: compareXML as String)
    }
}
