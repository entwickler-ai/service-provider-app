//
//  HomeView.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.userRole == "provider" {
                ProviderHomeView(authVM: authVM)
            } else {
                CustomerHomeView(authVM: authVM)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
