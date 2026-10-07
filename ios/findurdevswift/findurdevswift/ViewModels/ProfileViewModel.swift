//
//  ProfileViewModel.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation
import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

final class ProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isUpdating = false
    @Published var isUploadingImage = false
    @Published var isSuccess = false
    @Published var errorMessage: String?
    
    @Published var totalReviews = 0
    @Published var averageRating: Double = 0.0
    
    @Published var currentUser: UserModel?
    
    @Published var isLoadingStats = false
    @Published var statsError: String?
    @Published var servicesCount = 0
    
    @Published var activeRequestsCount = 0
    
    private let authService = AuthService.shared
    private let imageService = ImageService.shared
    private let serviceService = ServiceService.shared
    private let requestService = RequestService.shared
    private let db = Firestore.firestore()
    
    var currentUserId: String {
        return authService.getCurrentUID() ?? ""
    }
    
    func loadUserProfile() {
        guard !currentUserId.isEmpty else {
            errorMessage = "Benutzer nicht angemeldet"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        authService.fetchUser(uid: currentUserId) { [weak self] (result: Result<UserModel, Error>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let user):
                    self?.currentUser = user
                    
                    if user.role == "provider" {
                        self?.loadProviderStats()
                    }
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func loadProviderRating() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        ReviewService.shared.getReviewsForProvider(userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let reviews):
                    if reviews.isEmpty {
                        self?.averageRating = 0.0
                        self?.totalReviews = 0
                    } else {
                        let totalRating = reviews.map { Double($0.rating) }.reduce(0, +)
                        self?.averageRating = totalRating / Double(reviews.count)
                        self?.totalReviews = reviews.count
                    }
                case .failure:
                    self?.averageRating = 0.0
                    self?.totalReviews = 0
                }
            }
        }
    }
    
    func updateUserProfile(name: String, description: String, location: String) {
        guard var user = currentUser else {
            errorMessage = "Keine Benutzerdaten verfügbar"
            return
        }
        
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Name darf nicht leer sein"
            return
        }
        
        isUpdating = true
        errorMessage = nil
        
        user.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        user.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        user.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        
        db.collection("users").document(user.uid).setData(user.toDict()) { [weak self] error in
            DispatchQueue.main.async {
                self?.isUpdating = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.currentUser = user
                    self?.isSuccess = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self?.isSuccess = false
                    }
                }
            }
        }
    }
    
    func uploadProfileImage(from photoItem: PhotosPickerItem) {
        guard !currentUserId.isEmpty else {
            errorMessage = "Benutzer nicht angemeldet"
            return
        }
        
        isUploadingImage = true
        errorMessage = nil
        
        imageService.uploadProfileImage(userId: currentUserId, imageUri: photoItem) { [weak self] (result: Result<String, Error>) in
            DispatchQueue.main.async {
                self?.isUploadingImage = false
                
                switch result {
                case .success(let imageUrl):
                    self?.updateProfileImageUrl(imageUrl)
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func updateProfileImageUrl(_ imageUrl: String) {
        guard var user = currentUser else { return }
        
        if !user.profileImage.isEmpty {
            imageService.deleteProfileImage(imageUrl: user.profileImage) { (_: Result<Void, Error>) in
            }
        }
        
        user.profileImage = imageUrl
        
        db.collection("users").document(user.uid).setData(user.toDict()) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.currentUser = user
                }
            }
        }
    }
    
    func deleteProfileImage() {
        guard let user = currentUser, !user.profileImage.isEmpty else {
            return
        }
        
        isUploadingImage = true
        errorMessage = nil
        
        imageService.deleteProfileImage(imageUrl: user.profileImage) { [weak self] (result: Result<Void, Error>) in
            DispatchQueue.main.async {
                self?.isUploadingImage = false
                
                switch result {
                case .success:
                    self?.updateProfileImageUrl("")
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loadProviderStats() {
        guard let user = currentUser, user.role == "provider" else {
            return
        }
        
        isLoadingStats = true
        statsError = nil
        
        let group = DispatchGroup()
        var tempServicesCount = 0
        var tempAverageRating = 0.0
        var tempActiveRequestsCount = 0
        var hasError = false
        
        group.enter()
        serviceService.getServicesByProvider(user.uid) { (result: Result<[Service], Error>) in
            switch result {
            case .success(let services):
                tempServicesCount = services.count
                
                let ratingsAndCounts = services.compactMap { service -> (Double, Int)? in
                    guard let rating = service.rating, rating > 0 else { return nil }
                    return (rating, service.reviewCount)
                }
                
                if !ratingsAndCounts.isEmpty {
                    let totalWeightedRating = ratingsAndCounts.reduce(0.0) { sum, item in
                        sum + (item.0 * Double(item.1))
                    }
                    let totalReviews = ratingsAndCounts.reduce(0) { sum, item in
                        sum + item.1
                    }
                    
                    if totalReviews > 0 {
                        tempAverageRating = totalWeightedRating / Double(totalReviews)
                    }
                }
                
            case .failure:
                hasError = true
            }
            group.leave()
        }
        
        group.enter()
        requestService.getActiveRequestsCount(providerId: user.uid) { (result: Result<Int, Error>) in
            switch result {
            case .success(let count):
                tempActiveRequestsCount = count
            case .failure:
                hasError = true
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.isLoadingStats = false
            
            if hasError {
                self.statsError = "Fehler beim Laden der Statistiken"
            } else {
                self.servicesCount = tempServicesCount
                self.averageRating = tempAverageRating
                self.activeRequestsCount = tempActiveRequestsCount
            }
        }
    }
    
    func updateEmail(_ newEmail: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "ProfileViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nicht angemeldet"])))
            return
        }
        
        currentUser.sendEmailVerification(beforeUpdatingEmail: newEmail) { [weak self] error in
            if let error = error {
                completion(.failure(error))
            } else {
                DispatchQueue.main.async {
                    self?.errorMessage = "Verifizierungs-E-Mail wurde an \(newEmail) gesendet. Bitte bestätigen Sie die E-Mail, um die Änderung abzuschließen."
                }
                completion(.success(()))
            }
        }
    }
    
    func checkEmailUpdateStatus(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "ProfileViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nicht angemeldet"])))
            return
        }
        
        currentUser.reload { [weak self] error in
            if let error = error {
                completion(.failure(error))
            } else {
                if let updatedEmail = currentUser.email {
                    self?.updateEmailInFirestore(updatedEmail) { result in
                        switch result {
                        case .success:
                            completion(.success(true))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                } else {
                    completion(.success(false))
                }
            }
        }
    }
    
    private func updateEmailInFirestore(_ newEmail: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard var user = currentUser else {
            completion(.failure(NSError(domain: "ProfileViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Keine Benutzerdaten verfügbar"])))
            return
        }
        
        user.email = newEmail
        
        db.collection("users").document(user.uid).setData(user.toDict()) { [weak self] error in
            if let error = error {
                completion(.failure(error))
            } else {
                self?.currentUser = user
                completion(.success(()))
            }
        }
    }
    
    func updatePassword(_ newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "ProfileViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nicht angemeldet"])))
            return
        }
        
        currentUser.updatePassword(to: newPassword) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = currentUser else {
            completion(.failure(NSError(domain: "ProfileViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Keine Benutzerdaten verfügbar"])))
            return
        }
        
        guard let authUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "ProfileViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nicht angemeldet"])))
            return
        }
        
        db.collection("users").document(user.uid).delete { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if !user.profileImage.isEmpty {
                self?.imageService.deleteProfileImage(imageUrl: user.profileImage) { (_: Result<Void, Error>) in }
            }
            
            authUser.delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func resetState() {
        isSuccess = false
        errorMessage = nil
        statsError = nil
    }
    
    func refreshData() {
        loadUserProfile()
    }
    
    var isProvider: Bool {
        return currentUser?.role == "provider"
    }
    
    var isCustomer: Bool {
        return currentUser?.role == "customer"
    }
    
    var hasProfileImage: Bool {
        return !(currentUser?.profileImage.isEmpty ?? true)
    }
    
    var displayName: String {
        return currentUser?.name ?? "Benutzer"
    }
    
    var displayEmail: String {
        return currentUser?.email ?? ""
    }
    
    func validateProfileData(name: String, email: String) -> String? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return "Name darf nicht leer sein"
        }
        
        if trimmedName.count < 2 {
            return "Name muss mindestens 2 Zeichen lang sein"
        }
        
        if trimmedEmail.isEmpty {
            return "E-Mail darf nicht leer sein"
        }
        
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: trimmedEmail) {
            return "Bitte geben Sie eine gültige E-Mail-Adresse ein"
        }
        
        return nil
    }
    
    func exportUserData(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let user = currentUser else {
            completion(.failure(NSError(domain: "ProfileViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Keine Benutzerdaten verfügbar"])))
            return
        }
        
        var exportData: [String: Any] = [
            "profile": user.toDict(),
            "exportDate": DateFormatter().string(from: Date())
        ]
        
        if user.role == "provider" {
            serviceService.getServicesByProvider(user.uid) { (result: Result<[Service], Error>) in
                switch result {
                case .success(let services):
                    exportData["services"] = services.map { $0.toDict() }
                    completion(.success(exportData))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            completion(.success(exportData))
        }
    }
    
    func setupNotificationListeners() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ReviewCreatedSuccessfully"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let providerId = notification.userInfo?["providerId"] as? String,
               self?.currentUser?.uid == providerId {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self?.loadProviderStats()
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RequestStatusChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let providerId = notification.userInfo?["providerId"] as? String,
               self?.currentUser?.uid == providerId {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.loadProviderStats()
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RequestAccepted"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let providerId = notification.userInfo?["providerId"] as? String,
               self?.currentUser?.uid == providerId {
                self?.activeRequestsCount += 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.loadProviderStats()
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RequestCompleted"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let providerId = notification.userInfo?["providerId"] as? String,
               self?.currentUser?.uid == providerId {
                if self?.activeRequestsCount ?? 0 > 0 {
                    self?.activeRequestsCount -= 1
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.loadProviderStats()
                }
            }
        }
    }
}
