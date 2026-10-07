//
//  ReviewService.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 08.09.25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class ReviewService {
    static let shared = ReviewService()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    private init() {}

    func createReview(_ review: Review, completion: @escaping (Result<Void, Error>) -> Void) {
        hasUserReviewedRequest(review.requestId, review.customerId) { [weak self] result in
            switch result {
            case .success(let hasReviewed):
                if hasReviewed {
                    completion(.failure(NSError(domain: "ReviewService", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Sie haben diesen Service bereits bewertet"])))
                    return
                }
                
                self?.db.collection("reviews").document(review.id).setData(review.toDict()) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ReviewCreatedSuccessfully"),
                        object: nil,
                        userInfo: [
                            "serviceId": review.serviceId,
                            "providerId": review.providerId,
                            "rating": review.rating
                        ]
                    )
                    
                    self?.updateRatingsWithRetry(review: review, retryCount: 3, completion: completion)
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func updateRatingsWithRetry(review: Review, retryCount: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        updateServiceRatingImmediate(serviceId: review.serviceId, newReview: review) { [weak self] result in
            switch result {
            case .success:
                
                self?.updateProviderServicesRatingImmediate(review.providerId) { providerResult in
                    switch providerResult {
                    case .success:
                        completion(.success(()))
                    case .failure(_):
                        if retryCount > 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self?.updateRatingsWithRetry(review: review, retryCount: retryCount - 1, completion: completion)
                            }
                        } else {
                            completion(.success(()))
                        }
                    }
                }
                
            case .failure(_):
                if retryCount > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self?.updateRatingsWithRetry(review: review, retryCount: retryCount - 1, completion: completion)
                    }
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    private func updateServiceRatingImmediate(serviceId: String, newReview: Review, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("reviews")
            .whereField("serviceId", isEqualTo: serviceId)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success(()))
                    return
                }
                
                let reviews = documents.map { Review(from: $0.data()) }
                
                let averageRating: Double
                let reviewCount = reviews.count
                
                if reviewCount > 0 {
                    let totalRating = reviews.map { Double($0.rating) }.reduce(0, +)
                    averageRating = totalRating / Double(reviewCount)
                } else {
                    averageRating = 0.0
                }
                
                let updateData: [String: Any] = [
                    "rating": averageRating,
                    "reviewCount": reviewCount,
                    "updatedAt": Int64(Date().timeIntervalSince1970 * 1000)
                ]
                
                self?.db.collection("services").document(serviceId).updateData(updateData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
    }

    private func updateProviderServicesRatingImmediate(_ providerId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        getReviewsForProvider(providerId) { [weak self] result in
            switch result {
            case .success(let reviews):
                guard !reviews.isEmpty else {
                    completion(.success(()))
                    return
                }
                
                self?.db.collection("services")
                    .whereField("providerId", isEqualTo: providerId)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        
                        guard let documents = snapshot?.documents else {
                            completion(.success(()))
                            return
                        }
                        
                        let batch = self?.db.batch()
                        
                        for document in documents {
                            let serviceId = document.documentID
                            let serviceReviews = reviews.filter { $0.serviceId == serviceId }
                            
                            let serviceRating: Double
                            let serviceReviewCount = serviceReviews.count
                            
                            if serviceReviewCount > 0 {
                                serviceRating = serviceReviews.map { Double($0.rating) }.reduce(0, +) / Double(serviceReviewCount)
                            } else {
                                serviceRating = 0.0
                            }
                            
                            let updateData: [String: Any] = [
                                "rating": serviceRating,
                                "reviewCount": serviceReviewCount,
                                "updatedAt": Int64(Date().timeIntervalSince1970 * 1000)
                            ]
                            
                            batch?.updateData(updateData, forDocument: document.reference)
                        }
                        
                        batch?.commit { error in
                            if let error = error {
                                completion(.failure(error))
                            } else {
                                completion(.success(()))
                            }
                        }
                    }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getReviewsForProvider(
        _ providerId: String,
        completion: @escaping (Result<[Review], Error>) -> Void
    ) {
        db.collection("reviews")
            .whereField("providerId", isEqualTo: providerId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let reviews = documents.map { Review(from: $0.data()) }
                completion(.success(reviews))
            }
    }
    
    func getReviewsForService(
        _ serviceId: String,
        completion: @escaping (Result<[Review], Error>) -> Void
    ) {
        db.collection("reviews")
            .whereField("serviceId", isEqualTo: serviceId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let reviews = documents.map { Review(from: $0.data()) }
                completion(.success(reviews))
            }
    }
    
    func getReviewsByCustomer(
        _ customerId: String,
        completion: @escaping (Result<[Review], Error>) -> Void
    ) {
        db.collection("reviews")
            .whereField("customerId", isEqualTo: customerId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let reviews = documents.map { Review(from: $0.data()) }
                completion(.success(reviews))
            }
    }
    
    func hasUserReviewedRequest(
        _ requestId: String,
        _ customerId: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        db.collection("reviews")
            .whereField("requestId", isEqualTo: requestId)
            .whereField("customerId", isEqualTo: customerId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let hasReviewed = !(snapshot?.isEmpty ?? true)
                completion(.success(hasReviewed))
            }
    }
    
    func canUserReviewRequest(
        _ requestId: String,
        _ customerId: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        RequestService.shared.getRequestById(requestId: requestId) { requestResult in
            switch requestResult {
            case .success(let request):
                guard let request = request else {
                    completion(.failure(NSError(domain: "ReviewService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Anfrage nicht gefunden"])))
                    return
                }
                
                guard request.customerId == customerId && request.status == .completed else {
                    completion(.success(false))
                    return
                }
                
                self.hasUserReviewedRequest(requestId, customerId) { reviewResult in
                    switch reviewResult {
                    case .success(let hasReviewed):
                        completion(.success(!hasReviewed))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
        
    func getProviderRatingStats(
        _ providerId: String,
        completion: @escaping (Result<(averageRating: Double, totalReviews: Int), Error>) -> Void
    ) {
        db.collection("reviews")
            .whereField("providerId", isEqualTo: providerId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success((0.0, 0)))
                    return
                }
                
                let reviews = documents.map { Review(from: $0.data()) }
                
                if reviews.isEmpty {
                    completion(.success((0.0, 0)))
                } else {
                    let totalRating = reviews.map { Double($0.rating) }.reduce(0, +)
                    let averageRating = totalRating / Double(reviews.count)
                    completion(.success((averageRating, reviews.count)))
                }
            }
    }
    
    func getServiceRatingStats(
        _ serviceId: String,
        completion: @escaping (Result<(averageRating: Double, totalReviews: Int), Error>) -> Void
    ) {
        db.collection("reviews")
            .whereField("serviceId", isEqualTo: serviceId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success((0.0, 0)))
                    return
                }
                
                let reviews = documents.map { Review(from: $0.data()) }
                
                if reviews.isEmpty {
                    completion(.success((0.0, 0)))
                } else {
                    let totalRating = reviews.map { Double($0.rating) }.reduce(0, +)
                    let averageRating = totalRating / Double(reviews.count)
                    completion(.success((averageRating, reviews.count)))
                }
            }
    }
    
    private func updateServiceRating(
        serviceId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        getServiceRatingStats(serviceId) { [weak self] result in
            switch result {
            case .success(let (averageRating, totalReviews)):
                let updateData: [String: Any] = [
                    "rating": averageRating,
                    "reviewCount": totalReviews
                ]
                
                self?.db.collection("services").document(serviceId).updateData(updateData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func updateProviderServicesRating(
        _ providerId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        getReviewsForProvider(providerId) { [weak self] result in
            switch result {
            case .success(let reviews):
                guard !reviews.isEmpty else {
                    completion(.success(()))
                    return
                }
                
                self?.db.collection("services")
                    .whereField("providerId", isEqualTo: providerId)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        
                        guard let documents = snapshot?.documents else {
                            completion(.success(()))
                            return
                        }
                        
                        let batch = self?.db.batch()
                        
                        for document in documents {
                            let serviceId = document.documentID
                            let serviceReviews = reviews.filter { $0.serviceId == serviceId }
                            
                            let serviceRating: Double
                            let serviceReviewCount: Int
                            
                            if !serviceReviews.isEmpty {
                                serviceRating = serviceReviews.map { Double($0.rating) }.reduce(0, +) / Double(serviceReviews.count)
                                serviceReviewCount = serviceReviews.count
                            } else {
                                serviceRating = 0.0
                                serviceReviewCount = 0
                            }
                            
                            let updateData: [String: Any] = [
                                "rating": serviceRating,
                                "reviewCount": serviceReviewCount,
                                "updatedAt": Int64(Date().timeIntervalSince1970 * 1000)
                            ]
                            
                            batch?.updateData(updateData, forDocument: document.reference)
                        }
                        
                        batch?.commit { error in
                            if let error = error {
                                completion(.failure(error))
                            } else {
                                completion(.success(()))
                            }
                        }
                    }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func updateReview(
        _ reviewId: String,
        rating: Int,
        comment: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let updateData: [String: Any] = [
            "rating": rating,
            "comment": comment
        ]
        
        db.collection("reviews").document(reviewId).updateData(updateData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteReview(
        _ reviewId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection("reviews").document(reviewId).getDocument { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(.failure(NSError(domain: "ReviewService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Review nicht gefunden"])))
                return
            }
            
            let review = Review(from: data)
            
            self?.db.collection("reviews").document(reviewId).delete { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if !review.serviceId.isEmpty {
                    self?.updateServiceRating(serviceId: review.serviceId) { _ in
                    }
                }
                
                completion(.success(()))
            }
        }
    }
    
    func uploadCompletionFile(
        _ file: CompletionFile,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection("completion_files").document(file.id).setData(file.toDict()) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func getCompletionFiles(
        for requestId: String,
        completion: @escaping (Result<[CompletionFile], Error>) -> Void
    ) {
        db.collection("completion_files")
            .whereField("requestId", isEqualTo: requestId)
            .order(by: "uploadedAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let files = documents.map { CompletionFile(from: $0.data()) }
                completion(.success(files))
            }
    }
    
    func getReviewAnalytics(
        for providerId: String,
        completion: @escaping (Result<ReviewAnalytics, Error>) -> Void
    ) {
        getReviewsForProvider(providerId) { result in
            switch result {
            case .success(let reviews):
                let analytics = ReviewAnalytics(from: reviews)
                completion(.success(analytics))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

struct ReviewAnalytics {
    let totalReviews: Int
    let averageRating: Double
    let ratingDistribution: [Int: Int]
    let recentReviews: [Review]
    let monthlyReviewCount: Int
    
    init(from reviews: [Review]) {
        self.totalReviews = reviews.count
        self.averageRating = reviews.isEmpty ? 0.0 : reviews.averageRating
        self.ratingDistribution = reviews.ratingDistribution
        self.recentReviews = Array(reviews.prefix(5))
        
        let oneMonthAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        self.monthlyReviewCount = reviews.filter { $0.createdDate > oneMonthAgo }.count
    }
}
