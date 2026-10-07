//
//  Review.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 08.09.25.
//

import Foundation

struct Review: Identifiable, Codable, Equatable {
    var id: String
    var requestId: String
    var serviceId: String
    var providerId: String
    var providerName: String
    var customerId: String
    var customerName: String
    var rating: Int
    var comment: String
    var createdAt: Int64
    
    init(id: String = UUID().uuidString,
         requestId: String = "",
         serviceId: String = "",
         providerId: String = "",
         providerName: String = "",
         customerId: String = "",
         customerName: String = "",
         rating: Int = 0,
         comment: String = "",
         createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) {
        self.id = id
        self.requestId = requestId
        self.serviceId = serviceId
        self.providerId = providerId
        self.providerName = providerName
        self.customerId = customerId
        self.customerName = customerName
        self.rating = rating
        self.comment = comment
        self.createdAt = createdAt
    }
    
    init(from dict: [String: Any]) {
        self.id = dict["id"] as? String ?? UUID().uuidString
        self.requestId = dict["requestId"] as? String ?? ""
        self.serviceId = dict["serviceId"] as? String ?? ""
        self.providerId = dict["providerId"] as? String ?? ""
        self.providerName = dict["providerName"] as? String ?? ""
        self.customerId = dict["customerId"] as? String ?? ""
        self.customerName = dict["customerName"] as? String ?? ""
        self.rating = dict["rating"] as? Int ?? 0
        self.comment = dict["comment"] as? String ?? ""
        self.createdAt = dict["createdAt"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    func toDict() -> [String: Any] {
        return [
            "id": id,
            "requestId": requestId,
            "serviceId": serviceId,
            "providerId": providerId,
            "providerName": providerName,
            "customerId": customerId,
            "customerName": customerName,
            "rating": rating,
            "comment": comment,
            "createdAt": createdAt
        ]
    }
    
    var formattedCreatedAt: String {
        let date = Date(timeIntervalSince1970: TimeInterval(createdAt / 1000))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var createdDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(createdAt / 1000))
    }
    
    var ratingStars: String {
        return String(repeating: "⭐", count: rating)
    }
    
    var hasComment: Bool {
        return !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isValidRating: Bool {
        return rating >= 1 && rating <= 5
    }
    
    func isReviewBy(userId: String) -> Bool {
        return customerId == userId
    }
    
    func isReviewFor(providerId: String) -> Bool {
        return self.providerId == providerId
    }
}

struct CompletionFile: Identifiable, Codable, Equatable {
    var id: String
    var fileName: String
    var fileUrl: String
    var fileType: String
    var uploadedAt: Int64
    var requestId: String
    
    init(id: String = UUID().uuidString,
         fileName: String = "",
         fileUrl: String = "",
         fileType: String = "",
         uploadedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
         requestId: String = "") {
        self.id = id
        self.fileName = fileName
        self.fileUrl = fileUrl
        self.fileType = fileType
        self.uploadedAt = uploadedAt
        self.requestId = requestId
    }
    
    init(from dict: [String: Any]) {
        self.id = dict["id"] as? String ?? UUID().uuidString
        self.fileName = dict["fileName"] as? String ?? ""
        self.fileUrl = dict["fileUrl"] as? String ?? ""
        self.fileType = dict["fileType"] as? String ?? ""
        self.uploadedAt = dict["uploadedAt"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
        self.requestId = dict["requestId"] as? String ?? ""
    }
    
    func toDict() -> [String: Any] {
        return [
            "id": id,
            "fileName": fileName,
            "fileUrl": fileUrl,
            "fileType": fileType,
            "uploadedAt": uploadedAt,
            "requestId": requestId
        ]
    }
    
    var formattedUploadedAt: String {
        let date = Date(timeIntervalSince1970: TimeInterval(uploadedAt / 1000))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var uploadedDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(uploadedAt / 1000))
    }
    
    var fileIcon: String {
        switch fileType.lowercased() {
        case "pdf":
            return "doc.richtext"
        case "zip", "rar", "7z":
            return "archivebox"
        case "jpg", "jpeg", "png", "gif", "webp":
            return "photo"
        case "mp4", "mov", "avi":
            return "video"
        case "mp3", "wav", "m4a":
            return "music.note"
        default:
            return "doc"
        }
    }
    
    var isImage: Bool {
        let imageTypes = ["jpg", "jpeg", "png", "gif", "webp"]
        return imageTypes.contains(fileType.lowercased())
    }
    
    var isPDF: Bool {
        return fileType.lowercased() == "pdf"
    }
    
    var isArchive: Bool {
        let archiveTypes = ["zip", "rar", "7z"]
        return archiveTypes.contains(fileType.lowercased())
    }
}

struct ReviewState: Equatable {
    let isLoading: Bool
    let isSuccess: Bool
    let error: String?
    let reviews: [Review]
    let averageRating: Double
    let totalReviews: Int
    
    init(isLoading: Bool = false,
         isSuccess: Bool = false,
         error: String? = nil,
         reviews: [Review] = [],
         averageRating: Double = 0.0,
         totalReviews: Int = 0) {
        self.isLoading = isLoading
        self.isSuccess = isSuccess
        self.error = error
        self.reviews = reviews
        self.averageRating = averageRating
        self.totalReviews = totalReviews
    }
    
    var hasError: Bool {
        return error != nil
    }
    
    var isEmpty: Bool {
        return reviews.isEmpty
    }
    
    var isProcessing: Bool {
        return isLoading
    }
    
    static let idle = ReviewState()
    static let loading = ReviewState(isLoading: true)
    static let success = ReviewState(isSuccess: true)
    
    static func success(reviews: [Review]) -> ReviewState {
        let totalReviews = reviews.count
        let averageRating = totalReviews > 0 ?
            reviews.map { Double($0.rating) }.reduce(0, +) / Double(totalReviews) : 0.0
        
        return ReviewState(
            isSuccess: true,
            reviews: reviews,
            averageRating: averageRating,
            totalReviews: totalReviews
        )
    }
    
    static func error(_ message: String) -> ReviewState {
        return ReviewState(error: message)
    }
}

extension Review {
    var ratingColor: String {
        switch rating {
        case 5:
            return "green"
        case 4:
            return "blue"
        case 3:
            return "orange"
        case 1, 2:
            return "red"
        default:
            return "gray"
        }
    }
    
    var ratingDescription: String {
        switch rating {
        case 5:
            return "Hervorragend"
        case 4:
            return "Sehr gut"
        case 3:
            return "Gut"
        case 2:
            return "Befriedigend"
        case 1:
            return "Schlecht"
        default:
            return "Keine Bewertung"
        }
    }
}

extension Array where Element == Review {
    var averageRating: Double {
        guard !isEmpty else { return 0.0 }
        let totalRating = self.map { Double($0.rating) }.reduce(0, +)
        return totalRating / Double(count)
    }
    
    var ratingDistribution: [Int: Int] {
        var distribution = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        for review in self {
            distribution[review.rating, default: 0] += 1
        }
        return distribution
    }
    
    func reviewsForProvider(_ providerId: String) -> [Review] {
        return self.filter { $0.providerId == providerId }
    }
    
    func reviewsByCustomer(_ customerId: String) -> [Review] {
        return self.filter { $0.customerId == customerId }
    }
    
    func reviewsForService(_ serviceId: String) -> [Review] {
        return self.filter { $0.serviceId == serviceId }
    }
}
