//
//  Message.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation

enum MessageType: String, CaseIterable, Codable {
    case text = "TEXT"
    case image = "IMAGE"
    case file = "FILE"
    case link = "LINK"
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .image: return "Bild"
        case .file: return "Datei"
        case .link: return "Link"
        }
    }
    
    var icon: String {
        switch self {
        case .text: return "text.bubble"
        case .image: return "photo"
        case .file: return "doc"
        case .link: return "link"
        }
    }
}

struct Message: Identifiable, Codable, Equatable {
    var id: String
    var chatId: String
    var senderId: String
    var senderName: String
    var content: String
    var timestamp: Int64
    var type: MessageType
    var fileUrl: String
    var fileName: String
    var fileType: String
    var fileSize: Int64
    var isRead: Bool
    
    init(id: String = UUID().uuidString,
         chatId: String = "",
         senderId: String = "",
         senderName: String = "",
         content: String = "",
         timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
         type: MessageType = .text,
         fileUrl: String = "",
         fileName: String = "",
         fileType: String = "",
         fileSize: Int64 = 0,
         isRead: Bool = false) {
        self.id = id
        self.chatId = chatId
        self.senderId = senderId
        self.senderName = senderName
        self.content = content
        self.timestamp = timestamp
        self.type = type
        self.fileUrl = fileUrl
        self.fileName = fileName
        self.fileType = fileType
        self.fileSize = fileSize
        self.isRead = isRead
    }
    
    init(from dict: [String: Any]) {
        self.id = dict["id"] as? String ?? UUID().uuidString
        self.chatId = dict["chatId"] as? String ?? ""
        self.senderId = dict["senderId"] as? String ?? ""
        self.senderName = dict["senderName"] as? String ?? ""
        self.content = dict["content"] as? String ?? ""
        self.timestamp = dict["timestamp"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
        
        if let typeString = dict["type"] as? String,
           let messageType = MessageType(rawValue: typeString) {
            self.type = messageType
        } else {
            self.type = .text
        }
        
        self.fileUrl = dict["fileUrl"] as? String ?? ""
        self.fileName = dict["fileName"] as? String ?? ""
        self.fileType = dict["fileType"] as? String ?? ""
        self.fileSize = dict["fileSize"] as? Int64 ?? 0
        self.isRead = dict["isRead"] as? Bool ?? false
    }
    
    func toDict() -> [String: Any] {
        return [
            "id": id,
            "chatId": chatId,
            "senderId": senderId,
            "senderName": senderName,
            "content": content,
            "timestamp": timestamp,
            "type": type.rawValue,
            "fileUrl": fileUrl,
            "fileName": fileName,
            "fileType": fileType,
            "fileSize": fileSize,
            "isRead": isRead
        ]
    }
    
    var displayText: String {
        switch type {
        case .text:
            return content
        case .image:
            return "📷 Bild"
        case .file:
            switch fileType.lowercased() {
            case "pdf":
                return "📄 PDF-Datei"
            case "zip", "rar", "7z":
                return "🗃️ ZIP-Datei"
            default:
                return "📎 Datei"
            }
        case .link:
            return "🔗 Link"
        }
    }
    
    var hasAttachment: Bool {
        return type != .text && !fileUrl.isEmpty
    }
    
    var isImageMessage: Bool {
        return type == .image
    }
    
    var isFileMessage: Bool {
        return type == .file
    }
    
    var isLinkMessage: Bool {
        return type == .link
    }
    
    var formattedTimestamp: String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = DateFormatter()
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isYesterday(date) {
            formatter.dateFormat = "'Gestern' HH:mm"
        } else if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
            formatter.dateFormat = "dd.MM HH:mm"
        } else {
            formatter.dateFormat = "dd.MM.yy HH:mm"
        }
        
        return formatter.string(from: date)
    }
    
    var formattedFileSize: String {
        let bytes = fileSize
        
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return "\(bytes / 1024) KB"
        } else if bytes < 1024 * 1024 * 1024 {
            return "\(bytes / (1024 * 1024)) MB"
        } else {
            return "\(bytes / (1024 * 1024 * 1024)) GB"
        }
    }
    
    var isFromCurrentUser: Bool {
        return false
    }
    
    var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
    }
    
    func isSentBy(_ userId: String) -> Bool {
        return senderId == userId
    }
    
    var isPDF: Bool {
        return fileType.lowercased() == "pdf"
    }
    
    var isZip: Bool {
        return ["zip", "rar", "7z"].contains(fileType.lowercased())
    }
    
    var isValidUrl: Bool {
        guard type == .link else { return false }
        let urlString = fileUrl.isEmpty ? content : fileUrl
        return URL(string: urlString) != nil
    }
}
