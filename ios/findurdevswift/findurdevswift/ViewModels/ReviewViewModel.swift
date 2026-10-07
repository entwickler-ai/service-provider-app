//
//  ReviewViewModel.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 08.09.25.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class ReviewViewModel: ObservableObject {
    
    @Published var reviewState = ReviewState()
    
    private let reviewService: ReviewService
    private let requestService: RequestService
    private let authService: AuthService
    
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String {
        return authService.getCurrentUID() ?? ""
    }
    
    init(reviewService: ReviewService = ReviewService.shared,
         requestService: RequestService = RequestService.shared,
         authService: AuthService = AuthService.shared) {
        self.reviewService = reviewService
        self.requestService = requestService
        self.authService = authService
    }
    
    func submitReview(requestId: String, rating: Int, comment: String = "") {
        Task {
            await submitReviewAsync(requestId: requestId, rating: rating, comment: comment)
        }
    }
    
    func loadReviewsForProvider(_ providerId: String) {
        reviewState = ReviewState(isLoading: true)
        
        reviewService.getReviewsForProvider(providerId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let reviews):
                    self?.reviewState = ReviewState.success(reviews: reviews)
                case .failure(let error):
                    self?.reviewState = ReviewState(error: error.localizedDescription)
                }
            }
        }
    }
    
    func loadReviewsForService(_ serviceId: String) {
        reviewState = ReviewState(isLoading: true)
        
        reviewService.getReviewsForService(serviceId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let reviews):
                    self?.reviewState = ReviewState.success(reviews: reviews)
                case .failure(let error):
                    self?.reviewState = ReviewState(error: error.localizedDescription)
                }
            }
        }
    }
    
    func loadReviewsByCustomer(_ customerId: String) {
        reviewState = ReviewState(isLoading: true)
        
        reviewService.getReviewsByCustomer(customerId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let reviews):
                    self?.reviewState = ReviewState.success(reviews: reviews)
                case .failure(let error):
                    self?.reviewState = ReviewState(error: error.localizedDescription)
                }
            }
        }
    }
    
    func checkCanReviewRequest(_ requestId: String, _ customerId: String) {
        reviewService.canUserReviewRequest(requestId, customerId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let canReview):
                    self?.reviewState = ReviewState(isSuccess: canReview)
                case .failure(let error):
                    self?.reviewState = ReviewState(error: error.localizedDescription)
                }
            }
        }
    }
    
    func updateReview(_ reviewId: String, rating: Int, comment: String) {
        reviewState = ReviewState(isLoading: true)
        
        reviewService.updateReview(reviewId, rating: rating, comment: comment) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.reviewState = ReviewState(isSuccess: true)
                case .failure(let error):
                    self?.reviewState = ReviewState(error: error.localizedDescription)
                }
            }
        }
    }
    
    func deleteReview(_ reviewId: String) {
        reviewState = ReviewState(isLoading: true)
        
        reviewService.deleteReview(reviewId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.reviewState = ReviewState(isSuccess: true)
                case .failure(let error):
                    self?.reviewState = ReviewState(error: error.localizedDescription)
                }
            }
        }
    }
    
    private func submitReviewAsync(requestId: String, rating: Int, comment: String) async {
        reviewState = ReviewState(isLoading: true)
        
        do {
            let request = try await getRequestById(requestId)
            
            let userInfo = try await authService.getCurrentUserInfo()
            
            let review = Review(
                requestId: requestId,
                serviceId: request.serviceId,
                providerId: request.providerId,
                providerName: request.providerName,
                customerId: currentUserId,
                customerName: userInfo.name,
                rating: rating,
                comment: comment
            )
            
            try await createReview(review)
            
            reviewState = ReviewState(isSuccess: true)
            
            NotificationCenter.default.post(
                name: NSNotification.Name("ReviewCreatedSuccessfully"),
                object: nil,
                userInfo: [
                    "serviceId": request.serviceId,
                    "providerId": request.providerId,
                    "rating": rating
                ]
            )
            
        } catch {
            reviewState = ReviewState(error: error.localizedDescription)
        }
    }
    
    private func getRequestById(_ requestId: String) async throws -> Request {
        return try await withCheckedThrowingContinuation { continuation in
            requestService.getRequestById(requestId: requestId) { result in
                switch result {
                case .success(let request):
                    if let request = request {
                        continuation.resume(returning: request)
                    } else {
                        continuation.resume(throwing: NSError(domain: "ReviewViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request nicht gefunden"]))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func createReview(_ review: Review) async throws {
        try await withCheckedThrowingContinuation { continuation in
            reviewService.createReview(review) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func resetState() {
        reviewState = ReviewState()
    }
    
    func getProviderRatingStats(_ providerId: String) {
        reviewService.getProviderRatingStats(providerId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stats):
                    let reviews: [Review] = []
                    self?.reviewState = ReviewState(
                        isSuccess: true,
                        reviews: reviews,
                        averageRating: stats.averageRating,
                        totalReviews: stats.totalReviews
                    )
                case .failure(let error):
                    self?.reviewState = ReviewState(error: error.localizedDescription)
                }
            }
        }
    }
    
    func getServiceRatingStats(_ serviceId: String) {
        reviewService.getServiceRatingStats(serviceId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stats):
                    let reviews: [Review] = []
                    self?.reviewState = ReviewState(
                        isSuccess: true,
                        reviews: reviews,
                        averageRating: stats.averageRating,
                        totalReviews: stats.totalReviews
                    )
                case .failure(let error):
                    self?.reviewState = ReviewState(error: error.localizedDescription)
                }
            }
        }
    }
}
