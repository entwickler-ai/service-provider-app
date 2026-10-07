//
//  ChatDetailView.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ChatDetailView: View {
    let providerId: String
    let providerName: String
    let serviceTitle: String
    
    @StateObject private var vm = ChatViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var messageText = ""
    @State private var showingDocumentPicker = false
    @State private var showAIImprovement = false
    @State private var originalMessageText = ""
    @State private var improvedMessageText = ""
    @State private var showMessageSummary = false
    @State private var selectedMessageForSummary: Message?
    @State private var messageSummary = ""
    
    @State private var isSendingMessage = false
    @State private var sendingError: String?
    @State private var chatExistsOrCreated = false
    
    private var isCurrentUserProvider: Bool {
        return vm.currentUserId == providerId
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if vm.chatDetailState.isLoading && !chatExistsOrCreated {
                    ChatLoadingView()
                } else {
                    ChatMessagesView()
                    
                    ChatInputView()
                }
                
                if let error = sendingError {
                    ErrorBanner(message: error) {
                        sendingError = nil
                    }
                }
            }
            .navigationTitle(providerName)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            loadExistingChatIfAvailable()
        }
        .onDisappear {
            NotificationCenter.default.post(name: NSNotification.Name("ChatMessagesRead"), object: nil)
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerSheet(
                onFileSelected: { url in
                    sendFileMessage(url)
                },
                onImageSelected: { imageItem in
                    sendImageMessage(imageItem)
                },
                onLinkSelected: { url, description in
                    sendLinkMessage(url: url, description: description)
                }
            )
        }
        .sheet(isPresented: $showAIImprovement) {
            AITextImprovementSheet(
                originalText: originalMessageText,
                improvedText: improvedMessageText,
                onAccept: {
                    messageText = improvedMessageText
                    showAIImprovement = false
                },
                onReject: {
                    showAIImprovement = false
                }
            )
        }
        .sheet(isPresented: $showMessageSummary) {
            MessageSummarySheet(
                message: selectedMessageForSummary,
                summary: messageSummary,
                onDismiss: {
                    showMessageSummary = false
                    selectedMessageForSummary = nil
                    messageSummary = ""
                }
            )
        }
    }
    
    @ViewBuilder
    private func ChatMessagesView() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ServiceChatHeader()
                    
                    if vm.chatDetailState.isLoadingMessages {
                        ProgressView("Nachrichten werden geladen...")
                            .padding()
                    } else {
                        ForEach(vm.chatDetailState.messages, id: \.id) { message in
                            EnhancedMessageBubble(
                                message: message,
                                isCurrentUser: message.senderId == vm.currentUserId,
                                isProviderView: isCurrentUserProvider,
                                onSummaryRequested: { msg in
                                    requestMessageSummary(msg)
                                }
                            )
                            .id(message.id)
                        }
                    }
                }
                .padding()
            }
            .onChange(of: vm.chatDetailState.messages.count) { _, _ in
                if let lastMessage = vm.chatDetailState.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func ServiceChatHeader() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(providerName)")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Service: \(serviceTitle)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(vm.chatDetailState.chat != nil ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text(vm.chatDetailState.chat != nil ? "Verbunden" : "Bereit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func ChatInputView() -> some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 8) {
                if !isCurrentUserProvider {
                    Button(action: { showingDocumentPicker = true }) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .disabled(isSendingMessage || vm.chatDetailState.isUploadingFile)
                }
                
                Button(action: {
                    improveMessage()
                }) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(messageText.isEmpty ? .gray : .orange)
                }
                .disabled(messageText.isEmpty || isSendingMessage)
                
                TextField("Nachricht schreiben...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .lineLimit(1...4)
                    .disabled(isSendingMessage)
                
                Button(action: sendMessage) {
                    if isSendingMessage {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundColor(messageText.isEmpty ? .gray : .blue)
                    }
                }
                .disabled(messageText.isEmpty || isSendingMessage)
            }
            .padding()
            
            if vm.chatDetailState.isUploadingFile {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Anhang wird hochgeladen...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
    
    @ViewBuilder
    private func ErrorBanner(message: String, onDismiss: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
            
            Spacer()
            
            Button("Ausblenden", action: onDismiss)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.1))
    }
    
    @ViewBuilder
    private func ChatLoadingView() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Chat wird vorbereitet...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadExistingChatIfAvailable() {
        vm.loadExistingChat(otherUserId: providerId)
        
        NotificationCenter.default.post(name: NSNotification.Name("ChatOpened"), object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            chatExistsOrCreated = true
        }
    }
    
    private func refreshChatMessages() {
        guard let chatId = vm.chatDetailState.chat?.id else { return }
        vm.refreshChatMessages(chatId: chatId)
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        isSendingMessage = true
        sendingError = nil
        
        if vm.chatDetailState.chat == nil {
            vm.createChatAndSendMessage(
                otherUserId: providerId,
                serviceTitle: serviceTitle,
                message: text
            ) { [self] success in
                DispatchQueue.main.async {
                    self.isSendingMessage = false
                    if success {
                        self.messageText = ""
                        self.chatExistsOrCreated = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.refreshChatMessages()
                        }
                    } else {
                        self.sendingError = "Nachricht konnte nicht gesendet werden. Versuchen Sie es erneut."
                    }
                }
            }
        } else {
            vm.sendMessage(text) { [self] success in
                DispatchQueue.main.async {
                    self.isSendingMessage = false
                    if success {
                        self.messageText = ""
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.refreshChatMessages()
                        }
                    } else {
                        self.sendingError = "Nachricht konnte nicht gesendet werden. Versuchen Sie es erneut."
                    }
                }
            }
        }
    }
    
    private func sendImageMessage(_ imageItem: PhotosPickerItem) {
        if vm.chatDetailState.chat == nil {
            vm.createOrGetChat(
                otherUserId: providerId,
                serviceId: nil,
                serviceTitle: serviceTitle
            ) { [self] success in
                if success {
                    vm.sendImageMessage(imageItem) { [self] success in
                        DispatchQueue.main.async {
                            if success {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    self.refreshChatMessages()
                                }
                            } else {
                                self.sendingError = "Bild konnte nicht gesendet werden."
                            }
                        }
                    }
                } else {
                    sendingError = "Bild konnte nicht gesendet werden."
                }
            }
        } else {
            vm.sendImageMessage(imageItem) { [self] success in
                DispatchQueue.main.async {
                    if success {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.refreshChatMessages()
                        }
                    } else {
                        self.sendingError = "Bild konnte nicht gesendet werden."
                    }
                }
            }
        }
    }
    
    private func sendFileMessage(_ fileUrl: URL) {
        if vm.chatDetailState.chat == nil {
            vm.createOrGetChat(
                otherUserId: providerId,
                serviceId: nil,
                serviceTitle: serviceTitle
            ) { [self] success in
                if success {
                    vm.sendFileMessage(fileUrl: fileUrl, fileName: fileUrl.lastPathComponent) { [self] success in
                        DispatchQueue.main.async {
                            if success {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    self.refreshChatMessages()
                                }
                            } else {
                                self.sendingError = "Datei konnte nicht gesendet werden."
                            }
                        }
                    }
                } else {
                    sendingError = "Datei konnte nicht gesendet werden."
                }
            }
        } else {
            vm.sendFileMessage(fileUrl: fileUrl, fileName: fileUrl.lastPathComponent) { [self] success in
                DispatchQueue.main.async {
                    if success {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.refreshChatMessages()
                        }
                    } else {
                        self.sendingError = "Datei konnte nicht gesendet werden."
                    }
                }
            }
        }
    }
    
    private func sendLinkMessage(url: String, description: String) {
        if vm.chatDetailState.chat == nil {
            vm.createOrGetChat(
                otherUserId: providerId,
                serviceId: nil,
                serviceTitle: serviceTitle
            ) { [self] success in
                if success {
                    vm.sendLinkMessage(url: url, description: description) { [self] success in
                        DispatchQueue.main.async {
                            if success {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    self.refreshChatMessages()
                                }
                            } else {
                                self.sendingError = "Link konnte nicht gesendet werden."
                            }
                        }
                    }
                } else {
                    sendingError = "Link konnte nicht gesendet werden."
                }
            }
        } else {
            vm.sendLinkMessage(url: url, description: description) { [self] success in
                DispatchQueue.main.async {
                    if success {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.refreshChatMessages()
                        }
                    } else {
                        self.sendingError = "Link konnte nicht gesendet werden."
                    }
                }
            }
        }
    }
    
    private func improveMessage() {
        guard !messageText.isEmpty else { return }
        
        originalMessageText = messageText
        
        vm.improveMessage(messageText) { improved in
            if let improved = improved, improved != messageText {
                improvedMessageText = improved
                showAIImprovement = true
            }
        }
    }
    
    private func requestMessageSummary(_ message: Message) {
        selectedMessageForSummary = message
        
        vm.summarizeMessage(message.content) { summary in
            if let summary = summary {
                messageSummary = summary
                showMessageSummary = true
            }
        }
    }
}

struct EnhancedMessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    let isProviderView: Bool
    let onSummaryRequested: (Message) -> Void
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                MessageContent()
                
                HStack(spacing: 8) {
                    if shouldShowSummaryButton {
                        Button(action: {
                            onSummaryRequested(message)
                        }) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if isCurrentUser && message.isRead {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isCurrentUser ? Color.blue : Color(UIColor.systemGray5))
            .foregroundColor(isCurrentUser ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .frame(maxWidth: 280, alignment: isCurrentUser ? .trailing : .leading)
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
    
    private var shouldShowSummaryButton: Bool {
        guard message.type == .text else { return false }
        
        if isProviderView {
            return !isCurrentUser && message.content.count > 1
        }
        else {
            return !isCurrentUser && message.content.count > 1
        }
    }
    
    @ViewBuilder
    private func MessageContent() -> some View {
        switch message.type {
        case .text:
            Text(message.content)
                .font(.body)
                
        case .image:
            AsyncImage(url: URL(string: message.fileUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 120)
                    .overlay {
                        ProgressView()
                    }
            }
            .frame(maxWidth: 200, maxHeight: 200)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            if !message.content.isEmpty {
                Text(message.content)
                    .font(.caption)
                    .padding(.top, 4)
            }
            
        case .file:
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(message.fileName.isEmpty ? "Datei" : message.fileName)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    if message.fileSize > 0 {
                        Text(formatFileSize(message.fileSize))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    if let url = URL(string: message.fileUrl) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
        case .link:
            if let urlString = message.fileUrl.isEmpty ? nil : message.fileUrl,
               let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(message.content.isEmpty ? urlString : message.content)
                                .font(.caption)
                                .lineLimit(2)
                            
                            if !message.content.isEmpty {
                                Text(urlString)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private func formatTime(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = DateFormatter()
        
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}
