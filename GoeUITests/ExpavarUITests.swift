//
//  GoeUITests.swift
//  GoeUITests
//
//  Created by Kadhir M on 3/31/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import XCTest

class GoeUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let app = XCUIApplication()
        let element = app.childrenMatchingType(.Window).elementBoundByIndex(0).childrenMatchingType(.Other).elementBoundByIndex(2).childrenMatchingType(.Other).element
        element.tap()
        let kadhirManickamNavigationBar = app.navigationBars["Kadhir.Manickam"]
        kadhirManickamNavigationBar.buttons["Edit"].tap()
        element.tap()
        let scrollViewsQuery = app.scrollViews
        scrollViewsQuery.childrenMatchingType(.TextView).element.tap()
        let deleteKey = app.keys["delete"]
        deleteKey.tap()
        deleteKey.tap()
        deleteKey.tap()
        deleteKey.tap()
        app.buttons["Return"].tap()
        deleteKey.tap()
        deleteKey.tap()
        deleteKey.tap()
        deleteKey.tap()
        deleteKey.tap()
        deleteKey.tap()
        deleteKey.tap()
        deleteKey.tap()
        scrollViewsQuery.childrenMatchingType(.TextView).element
        element.tap()
        element.tap()
        app.buttons["Save"].tap()
        app.alerts["Updated!"].collectionViews.buttons["Okay"].tap()
        kadhirManickamNavigationBar.buttons["Profile"].tap()
    }
    
}
