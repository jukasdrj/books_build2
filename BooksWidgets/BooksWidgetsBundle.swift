//
//  BooksWidgetsBundle.swift
//  BooksWidgets
//
//  Live Activities and Widget Extension for Books App
//  Swift 6 compatible implementation
//

import WidgetKit
import SwiftUI

@main
struct BooksWidgetsBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            CSVImportLiveActivity()
        }
    }
}