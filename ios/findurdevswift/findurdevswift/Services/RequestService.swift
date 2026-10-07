//
//  RequestService.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

final class RequestService {
    static let shared = RequestService()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    private init() {}
    
    func createRequest(_ request: Request, completion: @escaping (Result<String, Error>) -> Void) {
        let requestId = UUID().uuidString
        var requestWithId = request
        requestWithId.id = requestId
        
        db.collection("requests").document(requestId).setData(requestWithId.toDict()) { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self?.createInitialStatusHistory(requestId: requestId, customerId: request.customerId) { historyResult in
                switch historyResult {
                case .success:
                    completion(.success(requestId))
                case .failure(_):
                    completion(.success(requestId))
                }
            }
        }
    }
    
    private func createInitialStatusHistory(requestId: String, customerId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let initialHistory = RequestStatusHistory(
            id: UUID().uuidString,
            requestId: requestId,
            status: .pending,
            notes: "Anfrage erstellt",
            updatedBy: customerId
        )
        
        db.collection("request_history")
            .document(initialHistory.id)
            .setData(initialHistory.toDict()) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    func getCustomerRequests(customerId: String) -> AnyPublisher<[Request], Error> {
        return Future<[Request], Error> { promise in
            self.db.collection("requests")
                .whereField("customerId", isEqualTo: customerId)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        promise(.success([]))
                        return
                    }
                    
                    let requests = documents
                        .map { Request(from: $0.data()) }
                        .filter { !$0.id.isEmpty }
                        .removingDuplicates()
                        .sorted { $0.createdAt > $1.createdAt }
                    
                    promise(.success(requests))
                }
        }
        .eraseToAnyPublisher()
    }
    
    func getProviderRequests(providerId: String) -> AnyPublisher<[Request], Error> {
        return Future<[Request], Error> { promise in
            self.db.collection("requests")
                .whereField("providerId", isEqualTo: providerId)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        promise(.success([]))
                        return
                    }
                    
                    let requests = documents
                        .map { Request(from: $0.data()) }
                        .filter { !$0.id.isEmpty }
                        .removingDuplicates()
                        .sorted { $0.createdAt > $1.createdAt }
                    
                    promise(.success(requests))
                }
        }
        .eraseToAnyPublisher()
    }
    
    func getRequestById(requestId: String, completion: @escaping (Result<Request?, Error>) -> Void) {
        db.collection("requests").document(requestId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(.success(nil))
                return
            }
            
            let request = Request(from: data)
            completion(.success(request))
        }
    }
    
    func getRequestsByStatus(userId: String, isProvider: Bool, status: RequestStatus) -> AnyPublisher<[Request], Error> {
        let field = isProvider ? "providerId" : "customerId"
        
        return Future<[Request], Error> { promise in
            self.db.collection("requests")
                .whereField(field, isEqualTo: userId)
                .whereField("status", isEqualTo: status.rawValue)
                .order(by: "updatedAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        promise(.success([]))
                        return
                    }
                    
                    let requests = documents
                        .map { Request(from: $0.data()) }
                        .filter { !$0.id.isEmpty }
                        .removingDuplicates()
                        .sorted { $0.updatedAt > $1.updatedAt }
                    
                    promise(.success(requests))
                }
        }
        .eraseToAnyPublisher()
    }
    
    func updateRequestStatus(
        requestId: String,
        newStatus: RequestStatus,
        response: String = "",
        updatedBy: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let batch = db.batch()
        
        let requestRef = db.collection("requests").document(requestId)
        requestRef.getDocument { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(.failure(NSError(domain: "RequestService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request nicht gefunden"])))
                return
            }
            
            var request = Request(from: data)
            request.status = newStatus
            request.updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
            if !response.isEmpty {
                request.providerResponse = response
            }
            
            batch.setData(request.toDict(), forDocument: requestRef)
            
            let historyEntry = RequestStatusHistory(
                id: UUID().uuidString,
                requestId: requestId,
                status: newStatus,
                notes: response,
                updatedBy: updatedBy
            )
            
            let historyRef = self?.db.collection("request_history").document(historyEntry.id)
            if let historyRef = historyRef {
                batch.setData(historyEntry.toDict(), forDocument: historyRef)
            }
            
            batch.commit { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func getRequestHistory(requestId: String, completion: @escaping (Result<[RequestStatusHistory], Error>) -> Void) {
        db.collection("request_history")
            .whereField("requestId", isEqualTo: requestId)
            .order(by: "timestamp", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let history = documents
                    .map { RequestStatusHistory(from: $0.data()) }
                    .filter { !$0.id.isEmpty }
                    .removingDuplicates()
                
                completion(.success(history))
            }
    }
    
    func getPendingRequestsCount(providerId: String, completion: @escaping (Result<Int, Error>) -> Void) {
        db.collection("requests")
            .whereField("providerId", isEqualTo: providerId)
            .whereField("status", isEqualTo: RequestStatus.pending.rawValue)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success(0))
                    return
                }
                
                let uniqueRequests = documents
                    .map { Request(from: $0.data()) }
                    .filter { !$0.id.isEmpty }
                    .removingDuplicates()
                
                completion(.success(uniqueRequests.count))
            }
    }
    
    func getActiveRequestsCount(providerId: String, completion: @escaping (Result<Int, Error>) -> Void) {
        db.collection("requests")
            .whereField("providerId", isEqualTo: providerId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success(0))
                    return
                }
                
                let activeRequests = documents
                    .map { Request(from: $0.data()) }
                    .filter { request in
                        !request.id.isEmpty && (request.status == .accepted || request.status == .inProgress)
                    }
                    .removingDuplicates()
                
                completion(.success(activeRequests.count))
            }
    }
    
    func deleteRequest(requestId: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("requests").document(requestId).getDocument { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(.failure(NSError(domain: "RequestService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request nicht gefunden"])))
                return
            }
            
            let request = Request(from: data)
            
            guard request.customerId == userId else {
                completion(.failure(NSError(domain: "RequestService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nicht berechtigt, diese Anfrage zu löschen"])))
                return
            }
            
            guard request.status == .pending else {
                completion(.failure(NSError(domain: "RequestService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nur ausstehende Anfragen können gelöscht werden"])))
                return
            }
            
            let batch = self?.db.batch()
            batch?.deleteDocument(snapshot!.reference)
            
            self?.db.collection("request_history")
                .whereField("requestId", isEqualTo: requestId)
                .getDocuments { historySnapshot, historyError in
                    if let historyError = historyError {
                        completion(.failure(historyError))
                        return
                    }
                    
                    historySnapshot?.documents.forEach { doc in
                        batch?.deleteDocument(doc.reference)
                    }
                    
                    batch?.commit { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                }
        }
    }
    
    func getRequestUpdates(
        customerId: String,
        since timestamp: Int64,
        completion: @escaping (Result<(accepted: Int, rejected: Int, completed: Int), Error>) -> Void
    ) {
        db.collection("requests")
            .whereField("customerId", isEqualTo: customerId)
            .whereField("updatedAt", isGreaterThan: timestamp)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success((0, 0, 0)))
                    return
                }
                
                let requests = documents
                    .map { Request(from: $0.data()) }
                    .filter { !$0.id.isEmpty }
                    .removingDuplicates()
                
                var acceptedCount = 0
                var rejectedCount = 0
                var completedCount = 0
                
                for request in requests {
                    switch request.status {
                    case .accepted:
                        acceptedCount += 1
                    case .rejected:
                        rejectedCount += 1
                    case .completed:
                        completedCount += 1
                    default:
                        break
                    }
                }
                
                completion(.success((acceptedCount, rejectedCount, completedCount)))
            }
    }
}

extension Array where Element: Equatable {
    func removingDuplicates() -> [Element] {
        var result = [Element]()
        for element in self {
            if !result.contains(element) {
                result.append(element)
            }
        }
        return result
    }
}

extension Array where Element == Request {
    func removingDuplicates() -> [Request] {
        var seen = Set<String>()
        return self.filter { request in
            guard !seen.contains(request.id) else { return false }
            seen.insert(request.id)
            return true
        }
    }
}

extension Array where Element == RequestStatusHistory {
    func removingDuplicates() -> [RequestStatusHistory] {
        var seen = Set<String>()
        return self.filter { history in
            guard !seen.contains(history.id) else { return false }
            seen.insert(history.id)
            return true
        }
    }
}
