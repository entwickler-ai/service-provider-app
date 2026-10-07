//
//  AuthState.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation

struct AuthState: Equatable {
    let isLoading: Bool
    let isSuccess: Bool
    let error: String?
    
    init(isLoading: Bool = false, isSuccess: Bool = false, error: String? = nil) {
        self.isLoading = isLoading
        self.isSuccess = isSuccess
        self.error = error
    }
    
    var hasError: Bool {
        return error != nil
    }
    
    var isIdle: Bool {
        return !isLoading && !isSuccess && error == nil
    }
    
    static let idle = AuthState()
    
    static let loading = AuthState(isLoading: true)
    
    static let success = AuthState(isSuccess: true)
    
    static func error(_ message: String) -> AuthState {
        return AuthState(error: message)
    }
    
    static func error(_ error: Error) -> AuthState {
        return AuthState(error: error.localizedDescription)
    }
}

struct ProfileState: Equatable {
    let isLoading: Bool
    let isUpdating: Bool
    let isUploadingImage: Bool
    let isSuccess: Bool
    let user: UserModel?
    let error: String?
    
    init(
        isLoading: Bool = false,
        isUpdating: Bool = false,
        isUploadingImage: Bool = false,
        isSuccess: Bool = false,
        user: UserModel? = nil,
        error: String? = nil
    ) {
        self.isLoading = isLoading
        self.isUpdating = isUpdating
        self.isUploadingImage = isUploadingImage
        self.isSuccess = isSuccess
        self.user = user
        self.error = error
    }
    
    var hasError: Bool {
        return error != nil
    }
    
    var isProcessing: Bool {
        return isLoading || isUpdating || isUploadingImage
    }
    
    static let idle = ProfileState()
    
    static let loading = ProfileState(isLoading: true)
    
    static func success(user: UserModel) -> ProfileState {
        return ProfileState(isSuccess: true, user: user)
    }
    
    static func error(_ message: String) -> ProfileState {
        return ProfileState(error: message)
    }
}

struct ProviderStatsState: Equatable {
    let isLoading: Bool
    let servicesCount: Int
    let averageRating: Double
    let totalReviews: Int
    let activeRequestsCount: Int
    let error: String?
    
    init(
        isLoading: Bool = false,
        servicesCount: Int = 0,
        averageRating: Double = 0.0,
        totalReviews: Int = 0,
        activeRequestsCount: Int = 0,
        error: String? = nil
    ) {
        self.isLoading = isLoading
        self.servicesCount = servicesCount
        self.averageRating = averageRating
        self.totalReviews = totalReviews
        self.activeRequestsCount = activeRequestsCount
        self.error = error
    }
    
    var hasError: Bool {
        return error != nil
    }
    
    static let idle = ProviderStatsState()
    
    static let loading = ProviderStatsState(isLoading: true)
    
    static func error(_ message: String) -> ProviderStatsState {
        return ProviderStatsState(error: message)
    }
}

struct ServiceState: Equatable {
    let isLoading: Bool
    let isUpdating: Bool
    let isUploadingImages: Bool
    let isSuccess: Bool
    let services: [Service]
    let error: String?
    
    init(
        isLoading: Bool = false,
        isUpdating: Bool = false,
        isUploadingImages: Bool = false,
        isSuccess: Bool = false,
        services: [Service] = [],
        error: String? = nil
    ) {
        self.isLoading = isLoading
        self.isUpdating = isUpdating
        self.isUploadingImages = isUploadingImages
        self.isSuccess = isSuccess
        self.services = services
        self.error = error
    }
    
    var hasError: Bool {
        return error != nil
    }
    
    var isProcessing: Bool {
        return isLoading || isUpdating || isUploadingImages
    }
    
    static let idle = ServiceState()
    
    static let loading = ServiceState(isLoading: true)
    
    static func success(services: [Service]) -> ServiceState {
        return ServiceState(isSuccess: true, services: services)
    }
    
    static func error(_ message: String) -> ServiceState {
        return ServiceState(error: message)
    }
}

struct ServiceDetailState: Equatable {
    let isLoading: Bool
    let service: Service?
    let provider: UserModel?
    let isOwner: Bool
    let isDeleted: Bool
    let error: String?
    
    init(
        isLoading: Bool = false,
        service: Service? = nil,
        provider: UserModel? = nil,
        isOwner: Bool = false,
        isDeleted: Bool = false,
        error: String? = nil
    ) {
        self.isLoading = isLoading
        self.service = service
        self.provider = provider
        self.isOwner = isOwner
        self.isDeleted = isDeleted
        self.error = error
    }
    
    var hasError: Bool {
        return error != nil
    }
    
    static let idle = ServiceDetailState()
    
    static let loading = ServiceDetailState(isLoading: true)
    
    static func error(_ message: String) -> ServiceDetailState {
        return ServiceDetailState(error: message)
    }
}
