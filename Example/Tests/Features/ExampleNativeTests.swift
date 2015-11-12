//
//  ExampleNativeTest.swift
//  XCTest-Gherkin
//
//  Created by Sam Dean on 05/11/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import XCTest
import XCTest_Gherkin

/**
 Run every scenario in every feature file found in the NativeFeatures group
*/
class ExampleNativeTest : NativeTestCase {
    
    override var path:NSURL? {
        get {
            return NSBundle.mainBundle().resourceURL?.URLByAppendingPathComponent("NativeFeatures")
        }
    }
    
}

/**
 Only run the scenarios tagged @sanity from the feature files in the NativeFeatures group
 */
class ExampleNativeSanityOnlyTest : NativeTestCase {
    
    // Specify the path to load the feature files from
    override var path:NSURL? {
        get {
            return NSBundle.mainBundle().resourceURL?.URLByAppendingPathComponent("NativeFeatures")
        }
    }
    
    override var tags:[String] {
        get {
            return ["@sanity"]
        }
    }
    
}
