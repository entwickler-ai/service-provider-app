//
//  Service.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation

struct Service: Identifiable, Codable, Equatable {
    var id: String
    var providerId: String
    var providerName: String
    var title: String
    var description: String
    var price: Double
    var tags: [String]
    var portfolioImages: [String]
    var location: String
    var rating: Double?
    var reviewCount: Int
    var createdAt: Int64
    var updatedAt: Int64
    
    init(id: String = UUID().uuidString,
         providerId: String = "",
         providerName: String = "",
         title: String = "",
         description: String = "",
         price: Double = 0.0,
         tags: [String] = [],
         portfolioImages: [String] = [],
         location: String = "",
         rating: Double? = nil,
         reviewCount: Int = 0,
         createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
         updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) {
        self.id = id
        self.providerId = providerId
        self.providerName = providerName
        self.title = title
        self.description = description
        self.price = price
        self.tags = tags
        self.portfolioImages = portfolioImages
        self.location = location
        self.rating = rating
        self.reviewCount = reviewCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from dict: [String: Any]) {
        self.id = dict["id"] as? String ?? UUID().uuidString
        self.providerId = dict["providerId"] as? String ?? ""
        self.providerName = dict["providerName"] as? String ?? ""
        self.title = dict["title"] as? String ?? ""
        self.description = dict["description"] as? String ?? ""
        self.price = dict["price"] as? Double ?? 0.0
        self.tags = dict["tags"] as? [String] ?? []
        self.portfolioImages = dict["portfolioImages"] as? [String] ?? []
        self.location = dict["location"] as? String ?? ""
        self.rating = dict["rating"] as? Double
        self.reviewCount = dict["reviewCount"] as? Int ?? 0
        self.createdAt = dict["createdAt"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
        self.updatedAt = dict["updatedAt"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "providerId": providerId,
            "providerName": providerName,
            "title": title,
            "description": description,
            "price": price,
            "tags": tags,
            "portfolioImages": portfolioImages,
            "location": location,
            "reviewCount": reviewCount,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
        
        if let rating = rating {
            dict["rating"] = rating
        }
        
        return dict
    }
    
    var formattedPrice: String {
        return "€\(Int(price))"
    }
    
    var formattedRating: String {
        guard let rating = rating, rating > 0 else { return "" }
        return String(format: "%.1f", rating)
    }
}
