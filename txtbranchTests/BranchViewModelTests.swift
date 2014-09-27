//
//  BranchViewModelTests.swift
//  txtbranch
//
//  Created by Daniel Mueller on 9/24/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

import UIKit
import XCTest
import txtbranch

class BranchViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testBranchViewModelEquality() {
        // This is an example of a functional test case.
        var model1 = BranchViewModel()
        var model2 = BranchViewModel()
        
        let objeq = model2.isEqual(model1)
        
        XCTAssert(objeq == 1,"model 1 and model 2 must be equal")
        
        XCTAssert(model1 == model2, "model 1 and model 2 must be equal")
        XCTAssert(!(model1 != model2), "model 1 and model 2 must be equal")
        
        model1.parentBranchKey = "parentBranchKey"
        
        XCTAssert(model1 != model2, "model 1 and model 2 must not be equal")
        XCTAssert(model2 != model1, "model 1 and model 2 must not be equal")
        
        model2.parentBranchKey = "parentBranchKey"
        
        XCTAssert(model1 == model2, "model 1 and model 2 must be equal")
        XCTAssert(model2 == model1, "model 1 and model 2 must be equal")
        
        model1.branches = ["parentBranchKey":["key":"parentBranchKey","field":"value"]]
        XCTAssert(model1 != model2, "model 1 and model 2 must not be equal")
        
        model2.branches = model1.branches
        XCTAssert(model1 == model2, "model 1 and model 2 must be equal")
        
    }

    func testBranchViewModelIsCurrentBranchValid() {
        // This is an example of a functional test case.
        var model = BranchViewModel()
        
        model.branchKeys = ["branch1"]
        model.branches = ["branch1":["key":"branch1"]]
        
        XCTAssertFalse(model.isCurrentBranchValid, "must not be valid")

        model.branches = ["branch1":["key":"branch1","content":"","link":""]]
        XCTAssertFalse(model.isCurrentBranchValid, "must not be valid")
        
        model.branches = ["branch1":["key":"branch1","content":"a","link":""]]
        XCTAssertFalse(model.isCurrentBranchValid, "must not be valid")
        
        model.branches = ["branch1":["key":"branch1","content":"","link":"a"]]
        XCTAssertFalse(model.isCurrentBranchValid, "must not be valid")
        
        model.branches = ["branch1":["key":"branch1","content":"a"]]
        XCTAssertFalse(model.isCurrentBranchValid, "must not be valid")
        
        model.branches = ["branch1":["key":"branch1","link":"a"]]
        XCTAssertFalse(model.isCurrentBranchValid, "must not be valid")
        
        model.branches = ["branch1":["key":"branch1","content":"a","link":"a"]]
        XCTAssert(model.isCurrentBranchValid, "must be valid")
        
    }
}
