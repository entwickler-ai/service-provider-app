//
//  Chat.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation

struct Chat: Identifiable, Codable, Equatable {
    var id: String
    var participants: [String]
    var participantNames: [String: String]
    var lastMessage: String
    var lastMessageTimestamp: Int64
    var lastMessageSenderId: String
    var unreadCount: [String: Int]
    var serviceId: String
    var serviceTitle: String
    var hiddenForUsers: [String]
    
    init(id: String = UUID().uuidString,
         participants: [String] = [],
         participantNames: [String: String] = [:],
         lastMessage: String = "",
         lastMessageTimestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
         lastMessageSenderId: String = "",
         unreadCount: [String: Int] = [:],
         serviceId: String = "",
         serviceTitle: String = "",
         hiddenForUsers: [String] = []) {
        self.id = id
        self.participants = participants
        self.participantNames = participantNames
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.lastMessageSenderId = lastMessageSenderId
        self.unreadCount = unreadCount
        self.serviceId = serviceId
        self.serviceTitle = serviceTitle
        self.hiddenForUsers = hiddenForUsers
    }
    
    init(from dict: [String: Any]) {
        self.id = dict["id"] as? String ?? UUID().uuidString
        self.participants = dict["participants"] as? [String] ?? []
        self.participantNames = dict["participantNames"] as? [String: String] ?? [:]
        self.lastMessage = dict["lastMessage"] as? String ?? ""
        self.lastMessageTimestamp = dict["lastMessageTimestamp"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
        self.lastMessageSenderId = dict["lastMessageSenderId"] as? String ?? ""
        self.unreadCount = dict["unreadCount"] as? [String: Int] ?? [:]
        self.serviceId = dict["serviceId"] as? String ?? ""
        self.serviceTitle = dict["serviceTitle"] as? String ?? ""
        self.hiddenForUsers = dict["hiddenForUsers"] as? [String] ?? []
    }
    
    func toDict() -> [String: Any] {
        return [
            "id": id,
            "participants": participants,
            "participantNames": participantNames,
            "lastMessage": lastMessage,
            "lastMessageTimestamp": lastMessageTimestamp,
            "lastMessageSenderId": lastMessageSenderId,
            "unreadCount": unreadCount,
            "serviceId": serviceId,
            "serviceTitle": serviceTitle,
            "hiddenForUsers": hiddenForUsers
        ]
    }
    
    func getOtherParticipantId(currentUserId: String) -> String? {
        return participants.first { $0 != currentUserId }
    }
    
    func getOtherParticipantName(currentUserId: String) -> String {
        guard let otherParticipantId = getOtherParticipantId(currentUserId: currentUserId) else {
            return "Unbekannter Nutzer"
        }
        return participantNames[otherParticipantId] ?? "Unbekannter Nutzer"
    }
    
    func getUnreadCountForUser(_ userId: String) -> Int {
        return unreadCount[userId] ?? 0
    }
    
    func isHiddenForUser(_ userId: String) -> Bool {
        return hiddenForUsers.contains(userId)
    }
    
    var hasService: Bool {
        return !serviceId.isEmpty
    }
    
    var formattedLastMessageTime: String {
        let date = Date(timeIntervalSince1970: TimeInterval(lastMessageTimestamp / 1000))
        let formatter = DateFormatter()
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isYesterday(date) {
            return "Gestern"
        } else if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
            formatter.dateFormat = "dd.MM"
        } else {
            formatter.dateFormat = "dd.MM.yy"
        }
        
        return formatter.string(from: date)
    }
}

struct ChatState: Equatable {
    let isLoading: Bool
    let chats: [Chat]
    let error: String?
    
    init(isLoading: Bool = false, chats: [Chat] = [], error: String? = nil) {
        self.isLoading = isLoading
        self.chats = chats
        self.error = error
    }
    
    var hasError: Bool {
        return error != nil
    }
    
    var isEmpty: Bool {
        return chats.isEmpty
    }
    
    static let idle = ChatState()
    static let loading = ChatState(isLoading: true)
    static func success(chats: [Chat]) -> ChatState {
        return ChatState(chats: chats)
    }
    static func error(_ message: String) -> ChatState {
        return ChatState(error: message)
    }
}

struct ChatDetailState: Equatable {
    let isLoading: Bool
    let chat: Chat?
    let messages: [Message]
    let error: String?
    let isLoadingMessages: Bool
    let sendingMessage: Bool
    let isUploadingFile: Bool
    
    init(isLoading: Bool = false,
         chat: Chat? = nil,
         messages: [Message] = [],
         error: String? = nil,
         isLoadingMessages: Bool = false,
         sendingMessage: Bool = false,
         isUploadingFile: Bool = false) {
        self.isLoading = isLoading
        self.chat = chat
        self.messages = messages
        self.error = error
        self.isLoadingMessages = isLoadingMessages
        self.sendingMessage = sendingMessage
        self.isUploadingFile = isUploadingFile
    }
    
    var hasError: Bool {
        return error != nil
    }
    
    var isProcessing: Bool {
        return isLoading || isLoadingMessages || sendingMessage || isUploadingFile
    }
    
    static let idle = ChatDetailState()
    static let loading = ChatDetailState(isLoading: true)
    static func error(_ message: String) -> ChatDetailState {
        return ChatDetailState(error: message)
    }
}

extension Calendar {
    func isToday(_ date: Date) -> Bool {
        return isDateInToday(date)
    }
    
    func isYesterday(_ date: Date) -> Bool {
        return isDateInYesterday(date)
    }
}
