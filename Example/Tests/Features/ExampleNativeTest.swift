//
//  ExampleNativeTest.swift
//  XCTest-Gherkin
//
//  Created by Sam Dean on 05/11/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import XCTest
import XCTest_Gherkin

class ExampleNativeTest : NativeTestCase {

    override func setUp() {
        super.setUp()
        
        let bundle = Bundle(for: type(of: self))
        self.path = bundle.resourceURL?.appendingPathComponent("NativeFeatures")
        
        XCTAssertNotNil(self.path)
        
        ColorLog.enabled = true
    }
    
    override func setUpBeforeScenario() {
        super.setUpBeforeScenario()
        print("Preparing before scenario")
    }
}
