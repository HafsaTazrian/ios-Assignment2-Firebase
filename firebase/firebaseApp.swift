//
//  firebaseApp.swift
//  firebase
//
//  Created by Hafsa Tazrian on 12/5/24.
//

import SwiftUI
import Firebase

@main
struct firebaseApp: App {
    init(){
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
