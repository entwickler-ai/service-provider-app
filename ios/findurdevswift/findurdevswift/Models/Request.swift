//
//  Request.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation

enum RequestStatus: String, CaseIterable, Codable {
    case pending = "PENDING"
    case accepted = "ACCEPTED"
    case rejected = "REJECTED"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"
    
    var displayName: String {
        switch self {
        case .pending: return "Ausstehend"
        case .accepted: return "Angenommen"
        case .rejected: return "Abgelehnt"
        case .inProgress: return "In Bearbeitung"
        case .completed: return "Abgeschlossen"
        case .cancelled: return "Abgebrochen"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .accepted: return "blue"
        case .rejected: return "red"
        case .inProgress: return "purple"
        case .completed: return "green"
        case .cancelled: return "gray"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .accepted: return "checkmark.circle"
        case .rejected: return "xmark.circle"
        case .inProgress: return "gearshape.2"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    
    func getNextPossibleStatuses(isProvider: Bool) -> [RequestStatus] {
        switch self {
        case .pending:
            return isProvider ? [.accepted, .rejected] : [.cancelled]
        case .accepted:
            return isProvider ? [.inProgress, .rejected] : [.cancelled]
        case .inProgress:
            return isProvider ? [.completed] : [.cancelled]
        default:
            return []
        }
    }
    
    func canBeUpdatedBy(isProvider: Bool) -> Bool {
        switch self {
        case .pending, .accepted:
            return true
        case .inProgress:
            return isProvider
        default:
            return false
        }
    }
}

struct Request: Identifiable, Codable, Equatable {
    var id: String
    var serviceId: String
    var serviceTitle: String
    var providerId: String
    var providerName: String
    var customerId: String
    var customerName: String
    var title: String
    var description: String
    var budget: Double
    var timeline: String
    var status: RequestStatus
    var createdAt: Int64
    var updatedAt: Int64
    var providerResponse: String
    var completionNotes: String
    var requirements: [String]
    var attachments: [String]
    var chatId: String
    
    init(id: String = UUID().uuidString,
         serviceId: String = "",
         serviceTitle: String = "",
         providerId: String = "",
         providerName: String = "",
         customerId: String = "",
         customerName: String = "",
         title: String = "",
         description: String = "",
         budget: Double = 0.0,
         timeline: String = "",
         status: RequestStatus = .pending,
         createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
         updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
         providerResponse: String = "",
         completionNotes: String = "",
         requirements: [String] = [],
         attachments: [String] = [],
         chatId: String = "") {
        self.id = id
        self.serviceId = serviceId
        self.serviceTitle = serviceTitle
        self.providerId = providerId
        self.providerName = providerName
        self.customerId = customerId
        self.customerName = customerName
        self.title = title
        self.description = description
        self.budget = budget
        self.timeline = timeline
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.providerResponse = providerResponse
        self.completionNotes = completionNotes
        self.requirements = requirements
        self.attachments = attachments
        self.chatId = chatId
    }
    
    init(from dict: [String: Any]) {
        self.id = dict["id"] as? String ?? UUID().uuidString
        self.serviceId = dict["serviceId"] as? String ?? ""
        self.serviceTitle = dict["serviceTitle"] as? String ?? ""
        self.providerId = dict["providerId"] as? String ?? ""
        self.providerName = dict["providerName"] as? String ?? ""
        self.customerId = dict["customerId"] as? String ?? ""
        self.customerName = dict["customerName"] as? String ?? ""
        self.title = dict["title"] as? String ?? ""
        self.description = dict["description"] as? String ?? ""
        self.budget = dict["budget"] as? Double ?? 0.0
        self.timeline = dict["timeline"] as? String ?? ""
        
        if let statusString = dict["status"] as? String,
           let requestStatus = RequestStatus(rawValue: statusString) {
            self.status = requestStatus
        } else {
            self.status = .pending
        }
        
        self.createdAt = dict["createdAt"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
        self.updatedAt = dict["updatedAt"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
        self.providerResponse = dict["providerResponse"] as? String ?? ""
        self.completionNotes = dict["completionNotes"] as? String ?? ""
        self.requirements = dict["requirements"] as? [String] ?? []
        self.attachments = dict["attachments"] as? [String] ?? []
        self.chatId = dict["chatId"] as? String ?? ""
    }
    
    func toDict() -> [String: Any] {
        return [
            "id": id,
            "serviceId": serviceId,
            "serviceTitle": serviceTitle,
            "providerId": providerId,
            "providerName": providerName,
            "customerId": customerId,
            "customerName": customerName,
            "title": title,
            "description": description,
            "budget": budget,
            "timeline": timeline,
            "status": status.rawValue,
            "createdAt": createdAt,
            "updatedAt": updatedAt,
            "providerResponse": providerResponse,
            "completionNotes": completionNotes,
            "requirements": requirements,
            "attachments": attachments,
            "chatId": chatId
        ]
    }
    
    var formattedBudget: String {
        return "€\(Int(budget))"
    }
    
    var createdDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(createdAt / 1000))
    }
    
    var updatedDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(updatedAt / 1000))
    }
    
    var formattedCreatedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdDate)
    }
    
    var formattedUpdatedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: updatedDate)
    }
    
    var hasResponse: Bool {
        return !providerResponse.isEmpty
    }
    
    var hasCompletionNotes: Bool {
        return !completionNotes.isEmpty
    }
    
    var hasRequirements: Bool {
        return !requirements.isEmpty
    }
    
    var hasAttachments: Bool {
        return !attachments.isEmpty
    }
    
    var isPending: Bool {
        return status == .pending
    }
    
    var isAccepted: Bool {
        return status == .accepted
    }
    
    var isCompleted: Bool {
        return status == .completed
    }
    
    var isActive: Bool {
        return [.accepted, .inProgress].contains(status)
    }
    
    var isClosed: Bool {
        return [.completed, .rejected, .cancelled].contains(status)
    }
    
    func isOwnedBy(userId: String) -> Bool {
        return customerId == userId
    }
    
    func isProvidedBy(userId: String) -> Bool {
        return providerId == userId
    }
    
    func canBeModifiedBy(userId: String, isProvider: Bool) -> Bool {
        return status.canBeUpdatedBy(isProvider: isProvider) &&
               (isProvider ? providerId == userId : customerId == userId)
    }
    
    var wasRecentlyUpdated: Bool {
        let dayInMilliseconds: Int64 = 24 * 60 * 60 * 1000
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        return (now - updatedAt) < dayInMilliseconds && updatedAt != createdAt
    }
}

struct RequestStatusHistory: Identifiable, Codable, Equatable {
    var id: String
    var requestId: String
    var status: RequestStatus
    var timestamp: Int64
    var notes: String
    var updatedBy: String
    
    init(id: String = UUID().uuidString,
         requestId: String = "",
         status: RequestStatus = .pending,
         timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
         notes: String = "",
         updatedBy: String = "") {
        self.id = id
        self.requestId = requestId
        self.status = status
        self.timestamp = timestamp
        self.notes = notes
        self.updatedBy = updatedBy
    }
    
    init(from dict: [String: Any]) {
        self.id = dict["id"] as? String ?? UUID().uuidString
        self.requestId = dict["requestId"] as? String ?? ""
        
        if let statusString = dict["status"] as? String,
           let requestStatus = RequestStatus(rawValue: statusString) {
            self.status = requestStatus
        } else {
            self.status = .pending
        }
        
        self.timestamp = dict["timestamp"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
        self.notes = dict["notes"] as? String ?? ""
        self.updatedBy = dict["updatedBy"] as? String ?? ""
    }
    
    func toDict() -> [String: Any] {
        return [
            "id": id,
            "requestId": requestId,
            "status": status.rawValue,
            "timestamp": timestamp,
            "notes": notes,
            "updatedBy": updatedBy
        ]
    }
    
    var formattedTimestamp: String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
    }
}

struct RequestState: Equatable {
    let isLoading: Bool
    let isSuccess: Bool
    let error: String?
    let requests: [Request]
    
    init(isLoading: Bool = false,
         isSuccess: Bool = false,
         error: String? = nil,
         requests: [Request] = []) {
        self.isLoading = isLoading
        self.isSuccess = isSuccess
        self.error = error
        self.requests = requests
    }
    
    var hasError: Bool {
        return error != nil
    }
    
    var isEmpty: Bool {
        return requests.isEmpty
    }
    
    var isProcessing: Bool {
        return isLoading
    }
    
    static let idle = RequestState()
    static let loading = RequestState(isLoading: true)
    static let success = RequestState(isSuccess: true)
    
    static func successWithRequests(_ requests: [Request]) -> RequestState {
        return RequestState(requests: requests)
    }
    
    static func error(_ message: String) -> RequestState {
        return RequestState(error: message)
    }
}

struct RequestDetailState: Equatable {
    let isLoading: Bool
    let request: Request?
    let statusHistory: [RequestStatusHistory]
    let error: String?
    let isUpdating: Bool
    
    init(isLoading: Bool = false,
         request: Request? = nil,
         statusHistory: [RequestStatusHistory] = [],
         error: String? = nil,
         isUpdating: Bool = false) {
        self.isLoading = isLoading
        self.request = request
        self.statusHistory = statusHistory
        self.error = error
        self.isUpdating = isUpdating
    }
    
    var hasError: Bool {
        return error != nil
    }
    
    var isProcessing: Bool {
        return isLoading || isUpdating
    }
    
    static let idle = RequestDetailState()
    static let loading = RequestDetailState(isLoading: true)
    
    static func error(_ message: String) -> RequestDetailState {
        return RequestDetailState(error: message)
    }
}
