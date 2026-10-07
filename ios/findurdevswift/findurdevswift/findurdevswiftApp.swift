//
//  findurdevswiftApp.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct FindurDevAppSwift: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authVM = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.currentUser != nil {
                    HomeView(authVM: authVM)
                } else {
                    LoginView(authVM: authVM)
                }
            }
            .withServices()
        }
    }
}
