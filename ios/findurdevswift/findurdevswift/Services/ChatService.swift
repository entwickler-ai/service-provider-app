//
//  ChatService.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

final class ChatService {
    static let shared = ChatService()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    private let imageService = ImageService.shared
    
    private init() {}
    
    func createOrGetChat(
        currentUserId: String,
        otherUserId: String,
        serviceId: String? = nil,
        serviceTitle: String? = nil,
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        guard !currentUserId.isEmpty, !otherUserId.isEmpty else {
            completion(.failure(NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User IDs dürfen nicht leer sein"])))
            return
        }
        
        checkExistingChat(currentUserId: currentUserId, otherUserId: otherUserId) { [weak self] (result: Result<Chat?, Error>) in
            switch result {
            case .success(let existingChat):
                if let chat = existingChat {
                    self?.refreshChatParticipantNames(chat: chat, currentUserId: currentUserId) { refreshResult in
                        completion(.success(refreshResult.getOrNull() ?? chat))
                    }
                } else {
                    self?.createNewChatWithRetry(
                        currentUserId: currentUserId,
                        otherUserId: otherUserId,
                        serviceId: serviceId,
                        serviceTitle: serviceTitle,
                        completion: completion
                    )
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func createNewChatWithRetry(
        currentUserId: String,
        otherUserId: String,
        serviceId: String?,
        serviceTitle: String?,
        completion: @escaping (Result<Chat, Error>) -> Void,
        retryCount: Int = 0
    ) {
        let group = DispatchGroup()
        var currentUserName = "Benutzer"
        var otherUserName = "Benutzer"
        var error: Error?
        
        group.enter()
        getUserInfo(userId: currentUserId) { result in
            switch result {
            case .success(let user):
                if let user = user {
                    currentUserName = user.name
                }
            case .failure(let err):
                error = err
            }
            group.leave()
        }
        
        group.enter()
        getUserInfo(userId: otherUserId) { [weak self] result in
            switch result {
            case .success(let user):
                if let user = user, !user.name.isEmpty {
                    otherUserName = user.name
                    group.leave()
                } else {
                    self?.loadProviderInfoFallback(otherUserId: otherUserId) { providerName in
                        otherUserName = providerName
                        group.leave()
                    }
                }
            case .failure(_):
                self?.loadProviderInfoFallback(otherUserId: otherUserId) { providerName in
                    otherUserName = providerName
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let chatId = UUID().uuidString
            let newChat = Chat(
                id: chatId,
                participants: [currentUserId, otherUserId],
                participantNames: [
                    currentUserId: currentUserName,
                    otherUserId: otherUserName
                ],
                unreadCount: [
                    currentUserId: 0,
                    otherUserId: 0
                ],
                serviceId: serviceId ?? "",
                serviceTitle: serviceTitle ?? ""
            )
            
            self.db.collection("chats").document(chatId).setData(newChat.toDict()) { err in
                if let err = err {
                    if retryCount < 3 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(retryCount + 1)) {
                            self.createNewChatWithRetry(
                                currentUserId: currentUserId,
                                otherUserId: otherUserId,
                                serviceId: serviceId,
                                serviceTitle: serviceTitle,
                                completion: completion,
                                retryCount: retryCount + 1
                            )
                        }
                    } else {
                        completion(.failure(err))
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        completion(.success(newChat))
                    }
                }
            }
        }
    }
    
    private func loadProviderInfoFallback(otherUserId: String, completion: @escaping (String) -> Void) {
        
        getUserInfo(userId: otherUserId) { [weak self] userResult in
            switch userResult {
            case .success(let user):
                if let user = user, !user.name.isEmpty && user.name != "Benutzer" {
                    completion(user.name)
                    return
                }
            case .failure(_):
                break
            }
            
            ServiceService.shared.getProviderInfo(otherUserId) { [weak self] providerResult in
                switch providerResult {
                case .success(let provider):
                    if let provider = provider, !provider.name.isEmpty {
                        completion(provider.name)
                        return
                    }
                case .failure(_):
                    break
                }
                
                self?.getProviderNameFromServices(providerId: otherUserId) { serviceName in
                    if !serviceName.isEmpty && serviceName != "Provider" {
                        completion(serviceName)
                        return
                    }
                    
                    self?.getNameFromFirebaseAuth(userId: otherUserId) { authName in
                        if !authName.isEmpty {
                            completion(authName)
                        } else {
                            completion("Dienstleister")
                        }
                    }
                }
            }
        }
    }

    private func getProviderNameFromServices(providerId: String, completion: @escaping (String) -> Void) {
        ServiceService.shared.getServicesByProvider(providerId) { result in
            switch result {
            case .success(let services):
                if let firstService = services.first, !firstService.providerName.isEmpty {
                    completion(firstService.providerName)
                } else {
                    completion("")
                }
            case .failure(_):
                completion("")
            }
        }
    }

    private func getNameFromFirebaseAuth(userId: String, completion: @escaping (String) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let email = data["email"] as? String {
                let emailName = email.components(separatedBy: "@").first ?? ""
                completion(emailName)
            } else {
                completion("")
            }
        }
    }
    
    private func checkExistingChat(
        currentUserId: String,
        otherUserId: String,
        completion: @escaping (Result<Chat?, Error>) -> Void
    ) {
        db.collection("chats")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success(nil))
                    return
                }
                
                for document in documents {
                    let chat = Chat(from: document.data())
                    if chat.participants.contains(otherUserId) {
                        completion(.success(chat))
                        return
                    }
                }
                
                completion(.success(nil))
            }
    }
    
    private func createNewChat(
        currentUserId: String,
        otherUserId: String,
        serviceId: String?,
        serviceTitle: String?,
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        let group = DispatchGroup()
        var currentUserName = "Benutzer"
        var otherUserName = "Benutzer"
        var error: Error?
        
        group.enter()
        getUserInfo(userId: currentUserId) { result in
            switch result {
            case .success(let user):
                if let user = user {
                    currentUserName = user.name
                }
            case .failure(let err):
                error = err
            }
            group.leave()
        }
        
        group.enter()
        getUserInfo(userId: otherUserId) { result in
            switch result {
            case .success(let user):
                if let user = user {
                    otherUserName = user.name
                } else {
                    if serviceId != nil {
                        ServiceService.shared.getProviderInfo(otherUserId) { (providerResult: Result<UserModel?, Error>) in
                            if let provider = providerResult.getOrNull() {
                                otherUserName = provider?.name ?? "Provider"
                            }
                            group.leave()
                        }
                        return
                    }
                }
            case .failure:
                break
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let chatId = UUID().uuidString
            let newChat = Chat(
                id: chatId,
                participants: [currentUserId, otherUserId],
                participantNames: [
                    currentUserId: currentUserName,
                    otherUserId: otherUserName
                ],
                unreadCount: [
                    currentUserId: 0,
                    otherUserId: 0
                ],
                serviceId: serviceId ?? "",
                serviceTitle: serviceTitle ?? ""
            )
            
            self.db.collection("chats").document(chatId).setData(newChat.toDict()) { err in
                if let err = err {
                    completion(.failure(err))
                } else {
                    completion(.success(newChat))
                }
            }
        }
    }
    
    func sendMessage(
        chatId: String,
        senderId: String,
        senderName: String,
        content: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let messageId = UUID().uuidString
        let message = Message(
            id: messageId,
            chatId: chatId,
            senderId: senderId,
            senderName: senderName,
            content: content
        )
        
        db.collection("messages").document(messageId).setData(message.toDict()) { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self?.updateChatLastMessage(
                chatId: chatId,
                senderId: senderId,
                lastMessage: content,
                completion: completion
            )
        }
    }
    
    func sendMessageWithAttachment(
        chatId: String,
        senderId: String,
        senderName: String,
        content: String = "",
        fileUrl: String,
        fileName: String,
        fileType: String,
        fileSize: Int64,
        messageType: MessageType,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let messageId = UUID().uuidString
        let message = Message(
            id: messageId,
            chatId: chatId,
            senderId: senderId,
            senderName: senderName,
            content: content.isEmpty ? fileName : content,
            type: messageType,
            fileUrl: fileUrl,
            fileName: fileName,
            fileType: fileType,
            fileSize: fileSize
        )
        
        db.collection("messages").document(messageId).setData(message.toDict()) { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self?.updateChatLastMessage(
                chatId: chatId,
                senderId: senderId,
                lastMessage: message.displayText,
                completion: completion
            )
        }
    }
    
    private func updateChatLastMessage(
        chatId: String,
        senderId: String,
        lastMessage: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let chatRef = db.collection("chats").document(chatId)
        
        chatRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(.failure(NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Chat nicht gefunden"])))
                return
            }
            
            var chat = Chat(from: data)
            
            var updatedUnreadCount = chat.unreadCount
            for participantId in chat.participants {
                if participantId != senderId {
                    updatedUnreadCount[participantId] = (updatedUnreadCount[participantId] ?? 0) + 1
                }
            }
            
            if !chat.hiddenForUsers.isEmpty {
                chat.hiddenForUsers.removeAll()
                print("Chat \(chatId) wurde aus hiddenForUsers entfernt - wird wieder sichtbar")
            }
            
            chat.lastMessage = lastMessage
            chat.lastMessageTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
            chat.lastMessageSenderId = senderId
            chat.unreadCount = updatedUnreadCount
            
            chatRef.setData(chat.toDict()) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func getUserChats(userId: String) -> AnyPublisher<[Chat], Error> {
        return Future<[Chat], Error> { promise in
            self.db.collection("chats")
                .whereField("participants", arrayContains: userId)
                .order(by: "lastMessageTimestamp", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        promise(.success([]))
                        return
                    }
                    
                    let chats = documents.compactMap { doc -> Chat? in
                        let chat = Chat(from: doc.data())
                        return chat.isHiddenForUser(userId) ? nil : chat
                    }
                    
                    promise(.success(chats))
                }
        }
        .eraseToAnyPublisher()
    }
    
    func getChatMessages(chatId: String) -> AnyPublisher<[Message], Error> {
        return Future<[Message], Error> { promise in
            self.db.collection("messages")
                .whereField("chatId", isEqualTo: chatId)
                .order(by: "timestamp", descending: false)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        promise(.success([]))
                        return
                    }
                    
                    let messages = documents.map { Message(from: $0.data()) }
                    promise(.success(messages))
                }
        }
        .eraseToAnyPublisher()
    }
    
    func getChatById(chatId: String, completion: @escaping (Result<Chat?, Error>) -> Void) {
        db.collection("chats").document(chatId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(.success(nil))
                return
            }
            
            let chat = Chat(from: data)
            completion(.success(chat))
        }
    }
    
    func markMessagesAsRead(chatId: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let chatRef = db.collection("chats").document(chatId)
        
        chatRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(.failure(NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Chat nicht gefunden"])))
                return
            }
            
            var chat = Chat(from: data)
            let currentUnreadCount = chat.unreadCount[userId] ?? 0
            
            if currentUnreadCount > 0 {
                chat.unreadCount[userId] = 0
                
                chatRef.setData(chat.toDict()) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        self.markIndividualMessagesAsRead(chatId: chatId, userId: userId, completion: completion)
                    }
                }
            } else {
                completion(.success(()))
            }
        }
    }
    
    private func markIndividualMessagesAsRead(chatId: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("messages")
            .whereField("chatId", isEqualTo: chatId)
            .whereField("senderId", isNotEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion(.success(()))
                    return
                }
                
                let batch = self.db.batch()
                for document in documents {
                    batch.updateData(["isRead": true], forDocument: document.reference)
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
    
    func deleteChat(chatId: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let chatRef = db.collection("chats").document(chatId)
        
        chatRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(.success(()))
                return
            }
            
            var chat = Chat(from: data)
            if !chat.hiddenForUsers.contains(userId) {
                chat.hiddenForUsers.append(userId)
                
                chatRef.setData(chat.toDict()) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            } else {
                completion(.success(()))
            }
        }
    }
    
    func getTotalUnreadCount(userId: String, completion: @escaping (Result<Int, Error>) -> Void) {
        db.collection("chats")
            .whereField("participants", arrayContains: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success(0))
                    return
                }
                
                var totalUnread = 0
                for document in documents {
                    let chat = Chat(from: document.data())
                    if !chat.isHiddenForUser(userId) {
                        totalUnread += chat.getUnreadCountForUser(userId)
                    }
                }
                
                completion(.success(totalUnread))
            }
    }
    
    private func getUserInfo(userId: String, completion: @escaping (Result<UserModel?, Error>) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                let fallbackUser = UserModel(uid: userId, name: "Benutzer")
                completion(.success(fallbackUser))
                return
            }
            
            let user = UserModel(from: data)
            completion(.success(user))
        }
    }
    
    func refreshChatParticipantNames(
        chat: Chat,
        currentUserId: String,
        completion: @escaping (Result<Chat, Error>) -> Void
    ) {
        let group = DispatchGroup()
        var updatedParticipantNames = chat.participantNames
        var hasChanges = false
        
        for participantId in chat.participants {
            let currentName = chat.participantNames[participantId]
            
            if currentName == nil ||
                currentName == "Benutzer" ||
                currentName == "Unknown User" ||
                currentName == "Provider" {
                
                group.enter()
                getUserInfo(userId: participantId) { [weak self] result in
                    switch result {
                    case .success(let user):
                        if let user = user, !user.name.isEmpty {
                            updatedParticipantNames[participantId] = user.name
                            hasChanges = true
                            group.leave()
                        } else {
                            self?.loadProviderInfoFallback(otherUserId: participantId) { providerName in
                                if providerName != "Provider" {
                                    updatedParticipantNames[participantId] = providerName
                                    hasChanges = true
                                }
                                group.leave()
                            }
                        }
                    case .failure(_):
                        self?.loadProviderInfoFallback(otherUserId: participantId) { providerName in
                            if providerName != "Provider" {
                                updatedParticipantNames[participantId] = providerName
                                hasChanges = true
                            }
                            group.leave()
                        }
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if hasChanges {
                var updatedChat = chat
                updatedChat.participantNames = updatedParticipantNames
                
                self.db.collection("chats").document(chat.id).setData(updatedChat.toDict()) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(updatedChat))
                    }
                }
            } else {
                completion(.success(chat))
            }
        }
    }
}
extension Result {
    func getOrNull() -> Success? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
}

extension ChatService {
    
    func findExistingChat(
        currentUserId: String,
        otherUserId: String,
        completion: @escaping (Result<Chat?, Error>) -> Void
    ) {
        guard !currentUserId.isEmpty, !otherUserId.isEmpty else {
            completion(.failure(NSError(domain: "ChatService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User IDs dürfen nicht leer sein"])))
            return
        }
        
        db.collection("chats")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success(nil))
                return
            }
            
            for document in documents {
                let chat = Chat(from: document.data())
                if chat.participants.contains(otherUserId) && !chat.isHiddenForUser(currentUserId) {
                    completion(.success(chat))
                    return
                }
            }
            
            completion(.success(nil))
        }
    }
}
