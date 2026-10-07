//
//  RegisterView.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI

struct RegisterView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showRoleSelection = false
    
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    
    @State private var nameError = ""
    @State private var emailError = ""
    @State private var passwordError = ""
    @State private var confirmPasswordError = ""

    var body: some View {
        VStack(spacing: 12) {
            
            Image("spa_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding(.bottom, 10)
            
            Text("Registrieren").font(.title)

            VStack(alignment: .leading, spacing: 4) {
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: name) { oldValue, newValue in
                        validateName(newValue)
                    }
                
                if !nameError.isEmpty {
                    Text(nameError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading, 4)
                }
            }
            
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
                    validateConfirmPassword(confirmPassword)
                }
                
                if !passwordError.isEmpty {
                    Text(passwordError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading, 4)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if isConfirmPasswordVisible {
                        TextField("Passwort bestätigen", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("Passwort bestätigen", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Button(action: {
                        isConfirmPasswordVisible.toggle()
                    }) {
                        Image(systemName: isConfirmPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 8)
                }
                .onChange(of: confirmPassword) { oldValue, newValue in
                    validateConfirmPassword(newValue)
                }
                
                if !confirmPasswordError.isEmpty {
                    Text(confirmPasswordError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading, 4)
                }
            }

            Button("Weiter zur Rollenwahl") {
                if validateAllInputs() {
                    showRoleSelection = true
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isFormValid())

            NavigationLink("Bereits ein Konto? Anmelden") {
                LoginView(authVM: authVM)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .navigationDestination(isPresented: $showRoleSelection) {
            RoleSelectionView(authVM: authVM, email: email, password: password, name: name)
        }
    }
    
    private func validateName(_ name: String) {
        if name.isEmpty {
            nameError = ""
            return
        }
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
            nameError = "Name muss mindestens 2 Zeichen lang sein"
        } else {
            nameError = ""
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
    
    private func validateConfirmPassword(_ confirmPassword: String) {
        if confirmPassword.isEmpty {
            confirmPasswordError = ""
            return
        }
        
        if confirmPassword != password {
            confirmPasswordError = "Passwörter stimmen nicht überein"
        } else {
            confirmPasswordError = ""
        }
    }
    
    private func isFormValid() -> Bool {
        return !name.isEmpty &&
               !email.isEmpty &&
               !password.isEmpty &&
               !confirmPassword.isEmpty &&
               nameError.isEmpty &&
               emailError.isEmpty &&
               passwordError.isEmpty &&
               confirmPasswordError.isEmpty
    }
    
    private func validateAllInputs() -> Bool {
        validateName(name)
        validateEmail(email)
        validatePassword(password)
        validateConfirmPassword(confirmPassword)
        
        return isFormValid()
    }
}
