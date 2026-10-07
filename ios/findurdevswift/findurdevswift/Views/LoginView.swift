//
//  LoginView.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    
    @State private var emailError = ""
    @State private var passwordError = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                
                Image("spa_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .padding(.bottom, 10)
                
                Text("Service Provider App").font(.largeTitle).bold()
                Text("Anmelden").font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: email) { oldValue, newValue in
                            validateEmail(newValue)
                        }
                    
                    if !emailError.isEmpty {
                        Text(emailError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.leading, 4)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if isPasswordVisible {
                            TextField("Passwort", text: $password)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("Passwort", text: $password)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 8)
                    }
                    .onChange(of: password) { oldValue, newValue in
                        validatePassword(newValue)
                    }
                    
                    if !passwordError.isEmpty {
                        Text(passwordError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.leading, 4)
                    }
                }

                if authVM.isLoading {
                    ProgressView()
                } else {
                    Button("Anmelden") {
                        if validateInputs() {
                            authVM.login(email: email, password: password)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || password.isEmpty || !emailError.isEmpty || !passwordError.isEmpty)
                }

                if let err = authVM.errorMessage {
                    Text(err).foregroundColor(.red).multilineTextAlignment(.center)
                }

                Spacer()

                NavigationLink("Noch kein Konto? Registrieren") {
                    RegisterView(authVM: authVM)
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
    }
    
    private func validateEmail(_ email: String) {
        if email.isEmpty {
            emailError = ""
            return
        }
        
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            emailError = "Bitte gültige Email eingeben"
        } else {
            emailError = ""
        }
    }
    
    private func validatePassword(_ password: String) {
        if password.isEmpty {
            passwordError = ""
            return
        }
        
        if password.count < 6 {
            passwordError = "Passwort muss mindestens 6 Zeichen lang sein"
        } else {
            passwordError = ""
        }
    }
    
    private func validateInputs() -> Bool {
        validateEmail(email)
        validatePassword(password)
        
        return emailError.isEmpty && passwordError.isEmpty && !email.isEmpty && !password.isEmpty
    }
}
