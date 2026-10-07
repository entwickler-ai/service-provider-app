//
//  ServiceService.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import SwiftUI
import PhotosUI

final class ServiceService {
    static let shared = ServiceService()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    private let storage = Storage.storage()
    
    private init() {}
    
    func createService(_ service: Service, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("services").document(service.id).setData(service.toDict()) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func getServices(completion: @escaping (Result<[Service], Error>) -> Void) {
        db.collection("services")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let services = snapshot?.documents.compactMap { doc -> Service? in
                    Service(from: doc.data())
                } ?? []
                
                completion(.success(services))
            }
    }
    
    func getServiceById(_ serviceId: String, completion: @escaping (Result<Service?, Error>) -> Void) {
        db.collection("services").document(serviceId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(.success(nil))
                return
            }
            
            let service = Service(from: data)
            completion(.success(service))
        }
    }
    
    func getServicesByProvider(_ providerId: String, completion: @escaping (Result<[Service], Error>) -> Void) {
        db.collection("services")
            .whereField("providerId", isEqualTo: providerId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                var services = snapshot?.documents.compactMap { doc -> Service? in
                    Service(from: doc.data())
                } ?? []
                
                services.sort { $0.createdAt > $1.createdAt }
                
                completion(.success(services))
            }
    }
    
    func updateService(_ service: Service, completion: @escaping (Result<Void, Error>) -> Void) {
        let updatedService = Service(
            id: service.id,
            providerId: service.providerId,
            providerName: service.providerName,
            title: service.title,
            description: service.description,
            price: service.price,
            tags: service.tags,
            portfolioImages: service.portfolioImages,
            location: service.location,
            rating: service.rating,
            reviewCount: service.reviewCount,
            createdAt: service.createdAt,
            updatedAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        
        db.collection("services").document(service.id).setData(updatedService.toDict()) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteService(_ serviceId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("services").document(serviceId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func updateServiceRating(_ serviceId: String, rating: Double, reviewCount: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let updateData: [String: Any] = [
            "rating": rating,
            "reviewCount": reviewCount,
            "updatedAt": Int64(Date().timeIntervalSince1970 * 1000)
        ]
        
        db.collection("services").document(serviceId).updateData(updateData, completion: { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        })
    }
    
    func uploadServiceImages(_ images: [PhotosPickerItem], for serviceId: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let group = DispatchGroup()
        var imageUrls: [String] = []
        var uploadError: Error?
        
        for (index, image) in images.enumerated() {
            group.enter()
            
            image.loadTransferable(type: Data.self) { result in
                switch result {
                case .success(let data):
                    guard let imageData = data else {
                        uploadError = NSError(domain: "ServiceService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bilddaten konnten nicht geladen werden"])
                        group.leave()
                        return
                    }
                    
                    let imageRef = self.storage.reference().child("service_images/\(serviceId)_\(index)_\(UUID().uuidString).jpg")
                    
                    imageRef.putData(imageData, metadata: nil) { metadata, error in
                        if let error = error {
                            uploadError = error
                            group.leave()
                            return
                        }
                        
                        imageRef.downloadURL { url, error in
                            if let error = error {
                                uploadError = error
                            } else if let url = url {
                                imageUrls.append(url.absoluteString)
                            }
                            group.leave()
                        }
                    }
                    
                case .failure(let error):
                    uploadError = error
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            if let error = uploadError {
                completion(.failure(error))
            } else {
                completion(.success(imageUrls))
            }
        }
    }
    
    func deleteServiceImage(_ imageUrl: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let imageRef = storage.reference(forURL: imageUrl)
        imageRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteMultipleServiceImages(_ imageUrls: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        let group = DispatchGroup()
        var deleteError: Error?
        
        for imageUrl in imageUrls {
            group.enter()
            deleteServiceImage(imageUrl) { result in
                if case .failure(let error) = result {
                    deleteError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if let error = deleteError {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func getProviderInfo(_ providerId: String, completion: @escaping (Result<UserModel?, Error>) -> Void) {
        guard !providerId.isEmpty else {
            completion(.success(nil))
            return
        }
        
        db.collection("users").document(providerId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(.success(nil))
                return
            }
            
            let user = UserModel(from: data)
            completion(.success(user))
        }
    }
    
    func searchServices(
        query: String = "",
        location: String = "",
        category: String = "",
        minPrice: Double? = nil,
        maxPrice: Double? = nil,
        sortOrder: String = "newest",
        completion: @escaping (Result<[Service], Error>) -> Void
    ) {
        getServices { result in
            switch result {
            case .success(var services):
                if !query.isEmpty {
                    services = services.filter { service in
                        service.title.localizedCaseInsensitiveContains(query) ||
                        service.description.localizedCaseInsensitiveContains(query) ||
                        service.tags.contains { $0.localizedCaseInsensitiveContains(query) }
                    }
                }
                
                if !location.isEmpty {
                    services = services.filter { service in
                        service.location.localizedCaseInsensitiveContains(location)
                    }
                }
                
                if !category.isEmpty {
                    services = services.filter { service in
                        service.tags.contains { $0.localizedCaseInsensitiveCompare(category) == .orderedSame } ||
                        service.title.localizedCaseInsensitiveContains(category)
                    }
                }
                
                if let minPrice = minPrice {
                    services = services.filter { $0.price >= minPrice }
                }
                
                if let maxPrice = maxPrice {
                    services = services.filter { $0.price <= maxPrice }
                }
                
                switch sortOrder {
                case "oldest":
                    services.sort { $0.createdAt < $1.createdAt }
                case "price_low":
                    services.sort { $0.price < $1.price }
                case "price_high":
                    services.sort { $0.price > $1.price }
                case "rating":
                    services.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
                default:
                    services.sort { $0.createdAt > $1.createdAt }
                }
                
                completion(.success(services))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
