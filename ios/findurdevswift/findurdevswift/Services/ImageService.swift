//
//  ImageService.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation
import UIKit
import PhotosUI
import FirebaseStorage
import _PhotosUI_SwiftUI

final class ImageService {
    static let shared = ImageService()
    
    private let storage = Storage.storage()
    
    private init() {}
    
    func uploadProfileImage(userId: String, imageUri: PhotosPickerItem, completion: @escaping (Result<String, Error>) -> Void) {
        imageUri.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                guard let imageData = data else {
                    completion(.failure(ImageServiceError.invalidImageData))
                    return
                }
                
                self.uploadProfileImageData(userId: userId, imageData: imageData, completion: completion)
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func uploadProfileImageData(userId: String, imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let fileName = "profile_\(userId)_\(UUID().uuidString).jpg"
        let storageRef = storage.reference()
            .child("profile_images")
            .child(fileName)
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(ImageServiceError.downloadUrlNotFound))
                }
            }
        }
    }
    
    func deleteProfileImage(imageUrl: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !imageUrl.isEmpty else {
            completion(.success(()))
            return
        }
        
        let storageRef = storage.reference(forURL: imageUrl)
        storageRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func uploadServiceImage(serviceId: String, imageUri: PhotosPickerItem, completion: @escaping (Result<String, Error>) -> Void) {
        imageUri.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                guard let imageData = data else {
                    completion(.failure(ImageServiceError.invalidImageData))
                    return
                }
                
                self.uploadServiceImageData(serviceId: serviceId, imageData: imageData, completion: completion)
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func uploadServiceImageData(serviceId: String, imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let fileName = "service_\(serviceId)_\(UUID().uuidString).jpg"
        let storageRef = storage.reference()
            .child("service_images")
            .child(fileName)
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(ImageServiceError.downloadUrlNotFound))
                }
            }
        }
    }
    
    func deleteServiceImage(imageUrl: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !imageUrl.isEmpty else {
            completion(.success(()))
            return
        }
        
        let storageRef = storage.reference(forURL: imageUrl)
        storageRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func uploadMultipleServiceImages(serviceId: String, imageUris: [PhotosPickerItem], completion: @escaping (Result<[String], Error>) -> Void) {
        let group = DispatchGroup()
        var uploadedUrls: [String] = []
        var uploadError: Error?
        
        for imageUri in imageUris {
            group.enter()
            
            uploadServiceImage(serviceId: serviceId, imageUri: imageUri) { result in
                switch result {
                case .success(let url):
                    uploadedUrls.append(url)
                case .failure(let error):
                    uploadError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if let error = uploadError {
                completion(.failure(error))
            } else {
                completion(.success(uploadedUrls))
            }
        }
    }
    
    func deleteMultipleServiceImages(imageUrls: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        let group = DispatchGroup()
        var deleteError: Error?
        
        for imageUrl in imageUrls {
            guard !imageUrl.isEmpty else { continue }
            
            group.enter()
            deleteServiceImage(imageUrl: imageUrl) { result in
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
    
    func uploadChatFile(chatId: String, fileUrl: URL, fileName: String, completion: @escaping (Result<(String, Int64), Error>) -> Void) {
        let sanitizedFileName = "chat_\(chatId)_\(UUID().uuidString)_\(fileName)"
        let storageRef = storage.reference()
            .child("chat_files")
            .child(sanitizedFileName)
        
        storageRef.putFile(from: fileUrl, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let fileSize = metadata?.size ?? 0
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success((url.absoluteString, fileSize)))
                } else {
                    completion(.failure(ImageServiceError.downloadUrlNotFound))
                }
            }
        }
    }
    
    func uploadChatImage(chatId: String, imageUri: PhotosPickerItem, completion: @escaping (Result<(String, Int64), Error>) -> Void) {
        imageUri.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                guard let imageData = data else {
                    completion(.failure(ImageServiceError.invalidImageData))
                    return
                }
                
                let fileName = "chat_img_\(chatId)_\(UUID().uuidString).jpg"
                let storageRef = self.storage.reference()
                    .child("chat_files")
                    .child(fileName)
                
                storageRef.putData(imageData, metadata: nil) { metadata, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    let fileSize = metadata?.size ?? 0
                    
                    storageRef.downloadURL { url, error in
                        if let error = error {
                            completion(.failure(error))
                        } else if let url = url {
                            completion(.success((url.absoluteString, fileSize)))
                        } else {
                            completion(.failure(ImageServiceError.downloadUrlNotFound))
                        }
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

enum ImageServiceError: Error, LocalizedError {
    case invalidImageData
    case downloadUrlNotFound
    case uploadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Bilddaten konnten nicht geladen werden"
        case .downloadUrlNotFound:
            return "Download-URL nicht gefunden"
        case .uploadFailed(let message):
            return "Upload fehlgeschlagen: \(message)"
        }
    }
}
