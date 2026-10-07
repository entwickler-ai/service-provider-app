//
//  AuthViewModel.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation
import Combine

final class AuthViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var isSuccess: Bool = false
    @Published var errorMessage: String? = nil

    @Published var currentUser: UserModel? = nil
    @Published var userRole: String? = nil

    private var cancellables = Set<AnyCancellable>()
    private let service = AuthService.shared

    init() {
        if let uid = service.getCurrentUID() {
            fetchUserRole(uid: uid)
        }
    }

    func register(email: String, password: String, name: String, role: String) {
        isLoading = true
        errorMessage = nil

        service.register(email: email, password: password, name: name, role: role) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let user):
                    self.currentUser = user
                    self.userRole = user.role
                    self.isSuccess = true
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.isSuccess = false
                }
            }
        }
    }

    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil

        service.login(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let user):
                    self.currentUser = user
                    self.userRole = user.role
                    self.isSuccess = true
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.isSuccess = false
                }
            }
        }
    }

    func fetchUserRole(uid: String) {
        isLoading = true
        service.fetchUser(uid: uid) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let user):
                    self.currentUser = user
                    self.userRole = user.role
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func logout() {
        service.logout()
        DispatchQueue.main.async {
            self.currentUser = nil
            self.userRole = nil
            self.isSuccess = false
            self.errorMessage = nil
        }
    }
}
