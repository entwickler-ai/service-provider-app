//
//  ServiceContainer.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftUI
import SwiftUI

final class ServiceContainer {
    static let shared = ServiceContainer()
    
    private init() {
    }
    
        lazy var auth: Auth = {
            return Auth.auth()
        }()
        
        lazy var firestore: Firestore = {
            let db = Firestore.firestore()
            
            let settings = FirestoreSettings()
            settings.cacheSettings = MemoryCacheSettings()
            db.settings = settings
            
            return db
        }()
        
        lazy var storage: Storage = {
            return Storage.storage()
        }()
        
        
        lazy var imageService: ImageService = {
            return ImageService.shared
        }()
        
        lazy var authService: AuthService = {
            return AuthService.shared
        }()
        
        lazy var serviceService: ServiceService = {
            return ServiceService.shared
        }()
        
        lazy var chatService: ChatService = {
            return ChatService.shared
        }()
        
        lazy var requestService: RequestService = {
            return RequestService.shared
        }()
        
        lazy var openAIService: OpenAIService = {
            return OpenAIService.shared
        }()
        
        lazy var reviewService: ReviewService = {
            return ReviewService.shared
        }()
    }

protocol ServiceProviding {
    var auth: Auth { get }
    var firestore: Firestore { get }
    var storage: Storage { get }
    var imageService: ImageService { get }
    var authService: AuthService { get }
    var serviceService: ServiceService { get }
    var chatService: ChatService { get }
    var requestService: RequestService { get }
    var reviewService: ReviewService { get }
    var openAIService: OpenAIService { get }
}

extension ServiceContainer: ServiceProviding {}

class AppServices: ObservableObject {
    let container: ServiceContainer
    
    init(container: ServiceContainer = .shared) {
        self.container = container
    }
    
    var auth: Auth { container.auth }
    var firestore: Firestore { container.firestore }
    var storage: Storage { container.storage }
    var imageService: ImageService { container.imageService }
    var authService: AuthService { container.authService }
    var serviceService: ServiceService { container.serviceService }
    var chatService: ChatService { container.chatService }
    var requestService: RequestService { container.requestService }
    var openAIService: OpenAIService { container.openAIService }
    var reviewService: ReviewService { container.reviewService }
}

extension View {
    func withServices() -> some View {
        self.environmentObject(AppServices())
    }
}
