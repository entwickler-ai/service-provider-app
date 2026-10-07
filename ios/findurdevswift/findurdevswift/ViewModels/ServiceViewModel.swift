//
//  ServiceViewModel.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation
import SwiftUI
import PhotosUI
import FirebaseAuth

final class ServiceViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isUploadingImages = false
    @Published var isSuccess = false
    @Published var errorMessage: String?
    
    @Published var services: [Service] = []
    @Published var currentService: Service?
    @Published var serviceProvider: UserModel?
    @Published var isOwner = false
    @Published var isDeleted = false
    
    private let serviceService = ServiceService.shared
    private let auth = Auth.auth()
    
    var currentUserId: String {
        return auth.currentUser?.uid ?? ""
    }
    
    func createService(
        title: String,
        description: String,
        price: Double,
        tags: [String],
        location: String,
        selectedImages: [PhotosPickerItem] = []
    ) {
        guard let providerId = auth.currentUser?.uid else {
            errorMessage = "Benutzer nicht angemeldet"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        serviceService.getProviderInfo(providerId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let provider):
                    let providerName = provider?.name ?? "Unbekannter Anbieter"
                    let serviceId = UUID().uuidString
                    
                    if !selectedImages.isEmpty {
                        self?.isUploadingImages = true
                        self?.serviceService.uploadServiceImages(selectedImages, for: serviceId) { uploadResult in
                            DispatchQueue.main.async {
                                self?.isUploadingImages = false
                                switch uploadResult {
                                case .success(let imageUrls):
                                    self?.createServiceWithImages(
                                        id: serviceId,
                                        providerId: providerId,
                                        providerName: providerName,
                                        title: title,
                                        description: description,
                                        price: price,
                                        tags: tags,
                                        location: location,
                                        imageUrls: imageUrls
                                    )
                                case .failure(let error):
                                    self?.isLoading = false
                                    self?.errorMessage = error.localizedDescription
                                }
                            }
                        }
                    } else {
                        self?.createServiceWithImages(
                            id: serviceId,
                            providerId: providerId,
                            providerName: providerName,
                            title: title,
                            description: description,
                            price: price,
                            tags: tags,
                            location: location,
                            imageUrls: []
                        )
                    }
                    
                case .failure(let error):
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func createServiceWithImages(
        id: String,
        providerId: String,
        providerName: String,
        title: String,
        description: String,
        price: Double,
        tags: [String],
        location: String,
        imageUrls: [String]
    ) {
        let service = Service(
            id: id,
            providerId: providerId,
            providerName: providerName,
            title: title,
            description: description,
            price: price,
            tags: tags,
            portfolioImages: imageUrls,
            location: location,
            rating: nil,
            reviewCount: 0
        )
        
        serviceService.createService(service) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.isSuccess = true
                    
                    NotificationCenter.default.post(name: NSNotification.Name("ServiceCreatedSuccessfully"), object: nil)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.isSuccess = false
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func loadServices() {
        isLoading = true
        errorMessage = nil
        
        serviceService.getServices { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let services):
                    var correctedServices = services
                    for (index, service) in correctedServices.enumerated() {
                        self?.autoCorrectServiceRating(service) { correctedService in
                            if let correctedService = correctedService {
                                correctedServices[index] = correctedService
                            }
                        }
                    }
                    self?.services = correctedServices
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func autoCorrectServiceRating(_ service: Service, completion: @escaping (Service?) -> Void) {
        ReviewService.shared.getReviewsForService(service.id) { result in
            switch result {
            case .success(let reviews):
                var correctedService = service
                
                if reviews.isEmpty {
                    correctedService.rating = 0.0
                    correctedService.reviewCount = 0
                } else {
                    correctedService.rating = reviews.map { Double($0.rating) }.reduce(0, +) / Double(reviews.count)
                    correctedService.reviewCount = reviews.count
                }
                
                completion(correctedService)
                
            case .failure:
                var correctedService = service
                correctedService.rating = 0.0
                correctedService.reviewCount = 0
                completion(correctedService)
            }
        }
    }
    
    func loadServicesByProvider(_ providerId: String? = nil) {
        let actualProviderId = providerId ?? currentUserId
        guard !actualProviderId.isEmpty else {
            errorMessage = "Benutzer nicht gefunden"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        serviceService.getServicesByProvider(actualProviderId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let services):
                    self?.services = services
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func loadServiceDetail(_ serviceId: String) {
        isLoading = true
        errorMessage = nil
        
        serviceService.getServiceById(serviceId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let service):
                    guard let service = service else {
                        self?.errorMessage = "Service nicht gefunden"
                        return
                    }
                    
                    self?.currentService = service
                    self?.isOwner = self?.currentUserId == service.providerId
                    self?.loadProviderInfo(service.providerId)
                    
                    self?.recalculateServiceRating(serviceId)
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func recalculateServiceRating(_ serviceId: String) {
        ReviewService.shared.getReviewsForService(serviceId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let reviews):
                    let correctRating: Double
                    let correctCount: Int
                    
                    if reviews.isEmpty {
                        correctRating = 0.0
                        correctCount = 0
                    } else {
                        correctRating = reviews.map { Double($0.rating) }.reduce(0, +) / Double(reviews.count)
                        correctCount = reviews.count
                    }
                    
                    self?.currentService?.rating = correctRating
                    self?.currentService?.reviewCount = correctCount
                    
                    self?.serviceService.updateServiceRating(serviceId, rating: correctRating, reviewCount: correctCount) { _ in }
                    
                case .failure:
                    self?.currentService?.rating = 0.0
                    self?.currentService?.reviewCount = 0
                }
            }
        }
    }
    
    private func loadProviderInfo(_ providerId: String) {
        serviceService.getProviderInfo(providerId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let provider):
                    self?.serviceProvider = provider
                case .failure:
                    break
                }
            }
        }
    }
    
    func updateService(
        serviceId: String,
        title: String,
        description: String,
        price: Double,
        tags: [String],
        location: String,
        existingImages: [String] = [],
        newImages: [PhotosPickerItem] = []
    ) {
        guard var service = currentService else {
            errorMessage = "Service nicht gefunden"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        if !newImages.isEmpty {
            isUploadingImages = true
            serviceService.uploadServiceImages(newImages, for: serviceId) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isUploadingImages = false
                    switch result {
                    case .success(let newImageUrls):
                        service.title = title
                        service.description = description
                        service.price = price
                        service.tags = tags
                        service.location = location
                        service.portfolioImages = existingImages + newImageUrls
                        service.updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
                        
                        self?.updateServiceData(service)
                        
                    case .failure(let error):
                        self?.isLoading = false
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        } else {
            service.title = title
            service.description = description
            service.price = price
            service.tags = tags
            service.location = location
            service.portfolioImages = existingImages
            service.updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
            
            updateServiceData(service)
        }
    }
    
    private func updateServiceData(_ service: Service) {
        serviceService.updateService(service) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.currentService = service
                    self?.isSuccess = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.isSuccess = false
                    }
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func deleteService(_ serviceId: String) {
        isLoading = true
        errorMessage = nil
        
        if let service = currentService, !service.portfolioImages.isEmpty {
            serviceService.deleteMultipleServiceImages(service.portfolioImages) { [weak self] _ in
                self?.deleteServiceData(serviceId)
            }
        } else {
            deleteServiceData(serviceId)
        }
    }
    
    private func deleteServiceData(_ serviceId: String) {
        serviceService.deleteService(serviceId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.isDeleted = true
                    
                    NotificationCenter.default.post(name: NSNotification.Name("ServiceDeletedSuccessfully"), object: nil)
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func searchServices(
        query: String = "",
        location: String = "",
        category: String = "",
        minPrice: Double? = nil,
        maxPrice: Double? = nil,
        sortOrder: String = "newest"
    ) {
        isLoading = true
        errorMessage = nil
        
        serviceService.searchServices(
            query: query,
            location: location,
            category: category,
            minPrice: minPrice,
            maxPrice: maxPrice,
            sortOrder: sortOrder
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let services):
                    self?.services = services
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func deleteServiceImage(_ imageUrl: String) {
        serviceService.deleteServiceImage(imageUrl) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if var service = self?.currentService {
                        service.portfolioImages.removeAll { $0 == imageUrl }
                        service.updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
                        self?.currentService = service
                        
                        self?.serviceService.updateService(service) { _ in }
                    }
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func resetState() {
        isSuccess = false
        errorMessage = nil
        isDeleted = false
    }
    
    func resetDetailState() {
        currentService = nil
        serviceProvider = nil
        isOwner = false
        errorMessage = nil
    }
    
    func loadServiceReviews() {
        guard let serviceId = currentService?.id else { return }
        
        ReviewService.shared.getReviewsForService(serviceId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let reviews):
                    if var service = self?.currentService {
                        let avgRating = reviews.isEmpty ? 0.0 :
                            reviews.map { Double($0.rating) }.reduce(0, +) / Double(reviews.count)
                        service.rating = avgRating
                        service.reviewCount = reviews.count
                        self?.currentService = service
                    }
                case .failure:
                    break
                }
            }
        }
    }
    
    func setupNotificationListeners() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ReviewCreatedSuccessfully"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let serviceId = notification.userInfo?["serviceId"] as? String,
               let rating = notification.userInfo?["rating"] as? Int,
               let currentService = self?.currentService,
               currentService.id == serviceId {
                
                let newReviewCount = currentService.reviewCount + 1
                let currentTotalRating = (currentService.rating ?? 0.0) * Double(currentService.reviewCount)
                let newAvgRating = (currentTotalRating + Double(rating)) / Double(newReviewCount)
                
                self?.currentService?.rating = newAvgRating
                self?.currentService?.reviewCount = newReviewCount
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let serviceId = notification.userInfo?["serviceId"] as? String,
                   let currentService = self?.currentService,
                   currentService.id == serviceId {
                    self?.loadServiceDetail(serviceId)
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
}
