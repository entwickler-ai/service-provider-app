//
//  ChatViewModel.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation
import SwiftUI
import Combine
import PhotosUI

final class ChatViewModel: ObservableObject {
    @Published var chatState = ChatState()
    @Published var chatDetailState = ChatDetailState()
    @Published var totalUnreadCount = 0
    
    private let chatService = ChatService.shared
    private let authService = AuthService.shared
    private let imageService = ImageService.shared
    private let openAIService = OpenAIService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    var currentUserId: String {
        return authService.getCurrentUID() ?? ""
    }
    
    init() {
        if !currentUserId.isEmpty {
            loadUserChats()
            loadTotalUnreadCount()
        }
        setupNotificationListeners()
    }
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ChatListViewed"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.markAllChatsAsViewed()
        }
    }
    
    private func markAllChatsAsViewed() {
        let chats = chatState.chats.filter { $0.getUnreadCountForUser(currentUserId) > 0 }
        
        for chat in chats {
            markMessagesAsRead(chatId: chat.id)
        }
        
        totalUnreadCount = 0
    }

    func loadUserChats() {
        guard !currentUserId.isEmpty else {
            chatState = ChatState.error("Benutzer nicht angemeldet")
            return
        }
        
        chatState = ChatState.loading
        
        chatService.getUserChats(userId: currentUserId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.chatState = ChatState.error(error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] chats in
                    self?.chatState = ChatState.success(chats: chats)
                    self?.updateTotalUnreadCount(from: chats)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.refreshChatParticipantNames()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func updateTotalUnreadCount(from chats: [Chat]) {
        let totalUnread = chats.reduce(0) { sum, chat in
            sum + chat.getUnreadCountForUser(currentUserId)
        }
        totalUnreadCount = totalUnread
    }
    
    func loadTotalUnreadCount() {
        guard !currentUserId.isEmpty else { return }
        
        chatService.getTotalUnreadCount(userId: currentUserId) { [weak self] result in
            DispatchQueue.main.async {
                if let count = result.getOrNull() {
                    self?.totalUnreadCount = count
                }
            }
        }
    }
    func refreshChatParticipantNames() {
        guard !currentUserId.isEmpty else { return }
        
        let chatsToRefresh = chatState.chats.filter { chat in
            return chat.participantNames.values.contains { name in
                name == "Provider" ||
                name == "Benutzer" ||
                name == "Unknown User" ||
                name == "Dienstleister" ||
                name.isEmpty ||
                name.contains("@")
            }
        }
        
        print("Found \(chatsToRefresh.count) chats that need name refresh")
        
        for chat in chatsToRefresh {
            chatService.refreshChatParticipantNames(chat: chat, currentUserId: currentUserId) { result in
                switch result {
                case .success(let updatedChat):
                    print("Successfully refreshed chat with \(updatedChat.participantNames)")
                case .failure(let error):
                    print("Failed to refresh chat: \(error.localizedDescription)")
                }
            }
        }
    }

    func forceRefreshAllChatNames() {
        guard !currentUserId.isEmpty else { return }
        
        for chat in chatState.chats {
            chatService.refreshChatParticipantNames(chat: chat, currentUserId: currentUserId) { result in
                print("Refreshed chat \(chat.id): \(result)")
            }
        }
    }
    
    func createOrGetChat(
        otherUserId: String,
        serviceId: String? = nil,
        serviceTitle: String? = nil,
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        guard !currentUserId.isEmpty else {
            chatDetailState = ChatDetailState.error("Benutzer nicht angemeldet")
            completion(false)
            return
        }
        
        chatDetailState = ChatDetailState.loading
        
        chatService.createOrGetChat(
            currentUserId: currentUserId,
            otherUserId: otherUserId,
            serviceId: serviceId,
            serviceTitle: serviceTitle
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let chat):
                    self?.chatDetailState = ChatDetailState(chat: chat)
                    self?.loadChatMessages(chatId: chat.id)
                    completion(true)
                    
                case .failure(let error):
                    self?.chatDetailState = ChatDetailState.error(error.localizedDescription)
                    completion(false)
                }
            }
        }
    }
    
    func loadChatDetail(chatId: String) {
        chatDetailState = ChatDetailState(isLoading: true)
        
        chatService.getChatById(chatId: chatId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let chat):
                    if let chat = chat {
                        self?.chatDetailState = ChatDetailState(chat: chat)
                        self?.loadChatMessages(chatId: chat.id)
                        self?.markMessagesAsRead(chatId: chat.id)
                    } else {
                        self?.chatDetailState = ChatDetailState.error("Chat nicht gefunden")
                    }
                    
                case .failure(let error):
                    self?.chatDetailState = ChatDetailState.error(error.localizedDescription)
                }
            }
        }
    }
    
    func loadChatMessages(chatId: String) {
        print("ChatViewModel: Lade Nachrichten für Chat: \(chatId)")
        
        updateChatDetailState { state in
            ChatDetailState(
                isLoading: false,
                chat: state.chat,
                messages: state.messages,
                error: nil,
                isLoadingMessages: true,
                sendingMessage: false,
                isUploadingFile: false
            )
        }
        
        chatService.getChatMessages(chatId: chatId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("ChatViewModel: Fehler beim Laden der Nachrichten: \(error.localizedDescription)")
                        self?.updateChatDetailState { state in
                            ChatDetailState(
                                isLoading: false,
                                chat: state.chat,
                                messages: state.messages,
                                error: error.localizedDescription,
                                isLoadingMessages: false,
                                sendingMessage: state.sendingMessage,
                                isUploadingFile: state.isUploadingFile
                            )
                        }
                    }
                },
                receiveValue: { [weak self] messages in
                    print("ChatViewModel: \(messages.count) Nachrichten geladen")
                    self?.updateChatDetailState { state in
                        ChatDetailState(
                            isLoading: false,
                            chat: state.chat,
                            messages: messages,
                            error: nil,
                            isLoadingMessages: false,
                            sendingMessage: state.sendingMessage,
                            isUploadingFile: state.isUploadingFile
                        )
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshChatMessages(chatId: String) {
        loadChatMessages(chatId: chatId)
    }
    
    func sendMessage(_ content: String, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let chat = chatDetailState.chat,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(false)
            return
        }
        
        updateChatDetailState { state in
            ChatDetailState(
                isLoading: state.isLoading,
                chat: state.chat,
                messages: state.messages,
                error: nil,
                isLoadingMessages: state.isLoadingMessages,
                sendingMessage: true,
                isUploadingFile: state.isUploadingFile
            )
        }
        
        getCurrentUserName { [weak self] senderName in
            self?.chatService.sendMessage(
                chatId: chat.id,
                senderId: self?.currentUserId ?? "",
                senderName: senderName,
                content: content.trimmingCharacters(in: .whitespacesAndNewlines)
            ) { [weak self] result in
                DispatchQueue.main.async {
                    self?.updateChatDetailState { state in
                        ChatDetailState(
                            isLoading: state.isLoading,
                            chat: state.chat,
                            messages: state.messages,
                            error: result.isFailure ? result.error?.localizedDescription : nil,
                            isLoadingMessages: state.isLoadingMessages,
                            sendingMessage: false,
                            isUploadingFile: state.isUploadingFile
                        )
                    }
                    completion(result.isSuccess)
                }
            }
        }
    }
    
    func createChatAndSendMessage(
        otherUserId: String,
        serviceTitle: String,
        message: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard !currentUserId.isEmpty && !message.isEmpty else {
            completion(false)
            return
        }
        
        createOrGetChat(
            otherUserId: otherUserId,
            serviceId: nil,
            serviceTitle: serviceTitle
        ) { [weak self] success in
            if success {
                self?.sendMessage(message, completion: completion)
            } else {
                completion(false)
            }
        }
    }
    
    func sendImageMessage(_ imageItem: PhotosPickerItem, description: String = "", completion: @escaping (Bool) -> Void = { _ in }) {
        guard let chat = chatDetailState.chat else {
            completion(false)
            return
        }
        
        updateChatDetailState { state in
            ChatDetailState(
                isLoading: state.isLoading,
                chat: state.chat,
                messages: state.messages,
                error: nil,
                isLoadingMessages: state.isLoadingMessages,
                sendingMessage: state.sendingMessage,
                isUploadingFile: true
            )
        }
        
        getCurrentUserName { [weak self] senderName in
            self?.imageService.uploadChatImage(chatId: chat.id, imageUri: imageItem) { [weak self] (uploadResult: Result<(String, Int64), Error>) in
                DispatchQueue.main.async { [weak self] in
                    switch uploadResult {
                    case .success(let (imageUrl, fileSize)):
                        self?.chatService.sendMessageWithAttachment(
                            chatId: chat.id,
                            senderId: self?.currentUserId ?? "",
                            senderName: senderName,
                            content: description,
                            fileUrl: imageUrl,
                            fileName: "image.jpg",
                            fileType: "image",
                            fileSize: fileSize,
                            messageType: .image
                        ) { [weak self] result in
                            DispatchQueue.main.async {
                                self?.updateChatDetailState { state in
                                    ChatDetailState(
                                        isLoading: state.isLoading,
                                        chat: state.chat,
                                        messages: state.messages,
                                        error: result.isFailure ? result.error?.localizedDescription : nil,
                                        isLoadingMessages: state.isLoadingMessages,
                                        sendingMessage: false,
                                        isUploadingFile: false
                                    )
                                }
                                completion(result.isSuccess)
                            }
                        }
                        
                    case .failure(let error):
                        self?.updateChatDetailState { state in
                            ChatDetailState(
                                isLoading: state.isLoading,
                                chat: state.chat,
                                messages: state.messages,
                                error: error.localizedDescription,
                                isLoadingMessages: state.isLoadingMessages,
                                sendingMessage: false,
                                isUploadingFile: false
                            )
                        }
                        completion(false)
                    }
                }
            }
        }
    }
    
    func sendFileMessage(fileUrl: URL, fileName: String, description: String = "", completion: @escaping (Bool) -> Void = { _ in }) {
        guard let chat = chatDetailState.chat else {
            completion(false)
            return
        }
        
        updateChatDetailState { state in
            ChatDetailState(
                isLoading: state.isLoading,
                chat: state.chat,
                messages: state.messages,
                error: nil,
                isLoadingMessages: state.isLoadingMessages,
                sendingMessage: state.sendingMessage,
                isUploadingFile: true
            )
        }
        
        getCurrentUserName { [weak self] senderName in
            self?.imageService.uploadChatFile(chatId: chat.id, fileUrl: fileUrl, fileName: fileName) { [weak self] (uploadResult: Result<(String, Int64), Error>) in
                DispatchQueue.main.async { [weak self] in
                    switch uploadResult {
                    case .success(let (uploadedUrl, fileSize)):
                        let fileType = self?.getFileType(from: fileName) ?? "file"
                        let messageType: MessageType = fileType == "image" ? .image : .file
                        
                        self?.chatService.sendMessageWithAttachment(
                            chatId: chat.id,
                            senderId: self?.currentUserId ?? "",
                            senderName: senderName,
                            content: description,
                            fileUrl: uploadedUrl,
                            fileName: fileName,
                            fileType: fileType,
                            fileSize: fileSize,
                            messageType: messageType
                        ) { [weak self] result in
                            DispatchQueue.main.async {
                                self?.updateChatDetailState { state in
                                    ChatDetailState(
                                        isLoading: state.isLoading,
                                        chat: state.chat,
                                        messages: state.messages,
                                        error: result.isFailure ? result.error?.localizedDescription : nil,
                                        isLoadingMessages: state.isLoadingMessages,
                                        sendingMessage: false,
                                        isUploadingFile: false
                                    )
                                }
                                completion(result.isSuccess)
                            }
                        }
                        
                    case .failure(let error):
                        self?.updateChatDetailState { state in
                            ChatDetailState(
                                isLoading: state.isLoading,
                                chat: state.chat,
                                messages: state.messages,
                                error: error.localizedDescription,
                                isLoadingMessages: state.isLoadingMessages,
                                sendingMessage: false,
                                isUploadingFile: false
                            )
                        }
                        completion(false)
                    }
                }
            }
        }
    }
    
    func sendLinkMessage(url: String, description: String = "", completion: @escaping (Bool) -> Void = { _ in }) {
        guard let chat = chatDetailState.chat,
              !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(false)
            return
        }
        
        var cleanUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !cleanUrl.hasPrefix("http://") && !cleanUrl.hasPrefix("https://") {
            cleanUrl = "https://" + cleanUrl
        }
        
        guard isValidUrl(cleanUrl) else {
            updateChatDetailState { state in
                ChatDetailState(
                    isLoading: state.isLoading,
                    chat: state.chat,
                    messages: state.messages,
                    error: "Ungültige URL. Bitte geben Sie eine gültige URL ein.",
                    isLoadingMessages: state.isLoadingMessages,
                    sendingMessage: state.sendingMessage,
                    isUploadingFile: state.isUploadingFile
                )
            }
            completion(false)
            return
        }
        
        updateChatDetailState { state in
            ChatDetailState(
                isLoading: state.isLoading,
                chat: state.chat,
                messages: state.messages,
                error: nil,
                isLoadingMessages: state.isLoadingMessages,
                sendingMessage: true,
                isUploadingFile: state.isUploadingFile
            )
        }
        
        getCurrentUserName { [weak self] senderName in
            self?.chatService.sendMessageWithAttachment(
                chatId: chat.id,
                senderId: self?.currentUserId ?? "",
                senderName: senderName,
                content: description.isEmpty ? cleanUrl : description,
                fileUrl: cleanUrl,
                fileName: cleanUrl,
                fileType: "link",
                fileSize: 0,
                messageType: .link
            ) { [weak self] result in
                DispatchQueue.main.async {
                    self?.updateChatDetailState { state in
                        ChatDetailState(
                            isLoading: state.isLoading,
                            chat: state.chat,
                            messages: state.messages,
                            error: result.isFailure ? result.error?.localizedDescription : nil,
                            isLoadingMessages: state.isLoadingMessages,
                            sendingMessage: false,
                            isUploadingFile: state.isUploadingFile
                        )
                    }
                    completion(result.isSuccess)
                }
            }
        }
    }
    
    func markMessagesAsRead(chatId: String) {
        chatService.markMessagesAsRead(chatId: chatId, userId: currentUserId) { [weak self] result in
            if result.isSuccess {
                DispatchQueue.main.async {
                    self?.loadTotalUnreadCount()
                }
            }
        }
    }
    
    func deleteChat(chatId: String) {
        chatService.deleteChat(chatId: chatId, userId: currentUserId) { [weak self] result in
            if result.isSuccess {
                DispatchQueue.main.async {
                    self?.loadUserChats()
                }
            }
        }
    }
    
    func improveMessage(_ text: String, completion: @escaping (String?) -> Void) {
        guard openAIService.canImproveText(text) else {
            completion(nil)
            return
        }
        
        Task {
            let improvedText = await openAIService.improveText(text, context: "Chat-Nachricht")
            await MainActor.run {
                completion(improvedText)
            }
        }
    }
    
    func summarizeMessage(_ text: String, completion: @escaping (String?) -> Void) {
        Task {
            let summary = await openAIService.summarizeText(text)
            await MainActor.run {
                completion(summary)
            }
        }
    }
    
    private func updateChatDetailState(_ updater: (ChatDetailState) -> ChatDetailState) {
        chatDetailState = updater(chatDetailState)
    }
    
    private func getCurrentUserName(completion: @escaping (String) -> Void) {
        authService.fetchUser(uid: currentUserId) { (result: Result<UserModel, Error>) in
            let userName = result.getOrNull()?.name ?? "Benutzer"
            completion(userName)
        }
    }
    
    func loadExistingChat(otherUserId: String) {
        guard !currentUserId.isEmpty else {
            chatDetailState = ChatDetailState.error("Benutzer nicht angemeldet")
            return
        }
        
        chatDetailState = ChatDetailState(isLoading: true)
        
        chatService.findExistingChat(currentUserId: currentUserId, otherUserId: otherUserId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let existingChat):
                    if let chat = existingChat {
                        self?.chatDetailState = ChatDetailState(chat: chat)
                        
                        self?.loadChatMessages(chatId: chat.id)
                        
                        self?.markMessagesAsRead(chatId: chat.id)
                        
                        print("Existierender Chat gefunden - Nachrichten werden geladen")
                    } else {
                        self?.chatDetailState = ChatDetailState()
                        print("Kein existierender Chat gefunden - bereit für neue Nachrichten")
                    }
                    
                case .failure(let error):
                    self?.chatDetailState = ChatDetailState.error(error.localizedDescription)
                    print("Fehler beim Laden des existierenden Chats: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func getFileType(from fileName: String) -> String {
        let fileExtension = fileName.components(separatedBy: ".").last?.lowercased() ?? ""
        
        switch fileExtension {
        case "jpg", "jpeg", "png", "gif", "webp", "heic", "bmp":
            return "image"
        case "pdf":
            return "pdf"
        case "zip", "rar", "7z", "tar", "gz", "bz2":
            return "zip"
        default:
            return "file"
        }
    }
    
    private func isValidUrl(_ urlString: String) -> Bool {
        var urlToTest = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !urlToTest.hasPrefix("http://") && !urlToTest.hasPrefix("https://") {
            urlToTest = "https://" + urlToTest
        }
        
        guard let url = URL(string: urlToTest) else { return false }
        guard url.host != nil else { return false }
        guard url.scheme == "http" || url.scheme == "https" else { return false }
        
        return true
    }
    
    func clearError() {
        if chatDetailState.hasError {
            updateChatDetailState { state in
                ChatDetailState(
                    isLoading: state.isLoading,
                    chat: state.chat,
                    messages: state.messages,
                    error: nil,
                    isLoadingMessages: state.isLoadingMessages,
                    sendingMessage: state.sendingMessage,
                    isUploadingFile: state.isUploadingFile
                )
            }
        }
    }
    
    func resetChatDetailState() {
        chatDetailState = ChatDetailState.idle
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cancellables.removeAll()
    }
}

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    var isFailure: Bool {
        return !isSuccess
    }
    
    var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}
