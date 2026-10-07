//
//  RoleSelectionView.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI

struct RoleSelectionView: View {
    @ObservedObject var authVM: AuthViewModel
    let email: String
    let password: String
    let name: String

    var body: some View {
        VStack(spacing: 20) {
            Text("Wähle deine Rolle").font(.title2).bold()

            Button {
                authVM.register(email: email, password: password, name: name, role: "customer")
            } label: {
                HStack {
                    Image(systemName: "person.fill")
                    Text("Ich bin Kunde")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                authVM.register(email: email, password: password, name: name, role: "provider")
            } label: {
                HStack {
                    Image(systemName: "briefcase.fill")
                    Text("Ich bin Dienstleister")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if authVM.isLoading {
                ProgressView()
            }

            if let err = authVM.errorMessage {
                Text(err).foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
    }
}
