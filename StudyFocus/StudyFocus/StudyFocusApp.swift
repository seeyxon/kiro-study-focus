//
//  StudyFocusApp.swift
//  StudyFocus
//
//  Created by 안시연 on 11/18/26.
//

import SwiftUI

@main
struct StudyFocusApp: App {
    @StateObject private var model = StudyFocusModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
    }
}
