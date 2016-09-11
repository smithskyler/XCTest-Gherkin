//
//  Example.swift
//  whats-new
//
//  Created by Sam Dean on 04/11/2015.
//  Copyright © 2015 net-a-porter. All rights reserved.
//

import Foundation
import ObjectiveC

import XCTest

open class NativeTestCase : XCTestCase {
    
    open var path:URL?
    open func setUpBeforeScenario() {}
    
    var testCaseClass: AnyClass!
    
    /**
     This method will dynamically create tests from the files in the folder specified by setting the path property on this instance.
    */
    func testRunNativeTests() {
        // If this hasn't been subclassed, just return
        guard type(of: self) != NativeTestCase.self else { return }
        
        // Sanity
        guard let path = self.path else {
            XCTAssertNotNil(self.path, "You must set the path for this test to run")
            return
        }
        
        guard let features = self.featuresForPath(path) else {
            XCTFail("Could not retrieve features from the path '\(path)'")
            return
        }
        
        self.perform(features)
    }
    
    func featuresForPath(_ path: URL) -> [NativeFeature]? {
        let manager = FileManager.default
        var isDirectory: ObjCBool = ObjCBool(false)
        guard manager.fileExists(atPath: path.path, isDirectory: &isDirectory) else {
            XCTFail("The path doesn not exist '\(path)'")
            return nil
        }
        
        if isDirectory.boolValue {
            // Get the files from that folder
            if let files = manager.enumerator(at: path, includingPropertiesForKeys: nil, options: [], errorHandler: nil) {
                return self.parseFeatureFiles(files)
            } else {
                XCTFail("Could not open the path '\(path)'")
            }
            
        } else {
            if let feature = self.parseFeatureFile(path) {
                return [feature]
            }
        }
        return nil
    }
    
    func parseFeatureFiles(_ files: FileManager.DirectoryEnumerator) -> [NativeFeature] {
        return files.map({ return self.parseFeatureFile($0 as! URL)!})
    }
    
    func parseFeatureFile(_ file: URL) -> NativeFeature? {
        guard let feature = NativeFeature(contentsOfURL:file, stepChecker:state.stepChecker) else {
            XCTFail("Could not parse feature at URL \(file.description)")
            return nil
        }
        return feature
    }
    
    func perform(_ features: [NativeFeature]) {
        if !state.stepChecker.hasMissingSteps() {
            features.forEach({performFeature($0)})
        } else {
            state.stepChecker.printTemplateCodeForAllMissingSteps()
        }
    }
    
    func performFeature(_ feature: NativeFeature) {
        // Create a test case to contain our tests
        let testClassName = "\(feature.featureDescription.camelCaseify)Tests"
        
        // If the class already exists means the feature could have been performed in other TestCases
        if NSClassFromString(testClassName) != nil {
            return
        }
        
        let testCaseClassOptional:AnyClass? = objc_allocateClassPair(XCTestCase.self, testClassName, 0)
        guard let testCaseClass = testCaseClassOptional else { XCTFail("Could not create test case class"); return }
        self.testCaseClass = testCaseClass
        
        // Return the correct number of tests
        let countBlock : @convention(block) (AnyObject) -> UInt = { _ in
            return UInt(feature.scenarios.count)
        }
        let imp = imp_implementationWithBlock(unsafeBitCast(countBlock, to: AnyObject.self))
        let sel = sel_registerName(strdup("testCaseCount"))
        var success = class_addMethod(testCaseClass, sel, imp, strdup("I@:"))
        XCTAssertTrue(success)
        
        // Return a name
        let nameBlock : @convention(block) (AnyObject) -> String = { _ in
            return feature.featureDescription.camelCaseify
        }
        let nameImp = imp_implementationWithBlock(unsafeBitCast(nameBlock, to: AnyObject.self))
        let nameSel = sel_registerName(strdup("name"))
        success = class_addMethod(testCaseClass, nameSel, nameImp, strdup("@@:"))
        XCTAssertTrue(success)
        
        // Return a test run class - make it the same as the current run
        let runBlock : @convention(block) (AnyObject) -> AnyObject! = { _ in
            return type(of: self.testRun!)
        }
        let runImp = imp_implementationWithBlock(unsafeBitCast(runBlock, to: AnyObject.self))
        let runSel = sel_registerName(strdup("testRunClass"))
        success = class_addMethod(testCaseClass, runSel, runImp, strdup("#@:"))
        XCTAssertTrue(success)
        
        NSLog(feature.description)
        
        // For each scenario, make an invocation that runs through the steps
        feature.scenarios.forEach { self.prepareScenarioInvocation($0, inFeature: feature) }
        
        // The test class is constructed, register it
        objc_registerClassPair(testCaseClass)
        
        // Add the test to our test suite
        testCaseClass.testInvocations().sorted { (a,b) in NSStringFromSelector(a.selector) > NSStringFromSelector(b.selector) }.forEach { invocation in
            let testCase = (testCaseClass as! XCTestCase.Type).init(invocation: invocation)
            testCase.run()
        }
    }
    
    func prepareScenarioInvocation(_ scenario: NativeScenario, inFeature feature: NativeFeature) {
        NSLog(scenario.description)
        
        // Create the block representing the test to be run
        let block : @convention(block) (XCTestCase)->() = { innerSelf in
            self.setUpBeforeScenario()
            if let background = feature.background {
                background.stepDescriptions.forEach { innerSelf.performStep($0) }
            }
            scenario.stepDescriptions.forEach { innerSelf.performStep($0) }
        }
        
        // Create the Method and selector
        let imp = imp_implementationWithBlock(unsafeBitCast(block, to: AnyObject.self))
        let sel = sel_registerName(scenario.selectorCString)
        
        // Add this selector to ourselves
        let typeString = strdup("v@:")
        let success = class_addMethod(self.testCaseClass, sel, imp, typeString)
        XCTAssertTrue(success, "Failed to add class method \(sel)")
    }
    
}
