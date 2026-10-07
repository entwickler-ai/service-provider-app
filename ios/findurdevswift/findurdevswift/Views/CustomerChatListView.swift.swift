//
//  CustomerChatListView.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI

struct CustomerChatListView: View {
    @StateObject private var vm = ChatViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                if vm.chatState.isLoading {
                    ProgressView("Chats werden geladen...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = vm.chatState.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        
                        Text(error)
                            .multilineTextAlignment(.center)
                        
                        Button("Erneut versuchen") {
                            vm.loadUserChats()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if vm.chatState.chats.isEmpty {
                    EmptyChatsView()
                } else {
                    ChatsList()
                }
            }
            .navigationTitle("Nachrichten")
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
            vm.loadUserChats()
        }
    }
    
    @ViewBuilder
    private func ChatsList() -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(vm.chatState.chats) { chat in
                    NavigationLink(destination: ChatDetailView(
                        providerId: chat.getOtherParticipantId(currentUserId: vm.currentUserId) ?? "",
                        providerName: chat.getOtherParticipantName(currentUserId: vm.currentUserId),
                        serviceTitle: chat.serviceTitle
                    )) {
                        ChatCard(
                            chat: chat,
                            currentUserId: vm.currentUserId,
                            onDelete: {
                                vm.deleteChat(chatId: chat.id)
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func EmptyChatsView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "message")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Keine Nachrichten")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Sie haben noch keine Unterhaltungen gestartet.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ChatCard: View {
    let chat: Chat
    let currentUserId: String
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.getOtherParticipantName(currentUserId: currentUserId))
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(chat.formattedLastMessageTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !chat.serviceTitle.isEmpty {
                    Text(chat.serviceTitle)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Text(chat.lastMessage.isEmpty ? "Noch keine Nachricht" : chat.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            VStack(spacing: 8) {
                if chat.getUnreadCountForUser(currentUserId) > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .overlay {
                            Text("\(chat.getUnreadCountForUser(currentUserId))")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                } else {
                    Spacer()
                        .frame(height: 20)
                }
                
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .frame(width: 30, height: 30)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
        .alert("Chat verstecken", isPresented: $showDeleteAlert) {
            Button("Verstecken", role: .destructive) {
                onDelete()
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Möchten Sie diesen Chat aus Ihrer Liste entfernen? Der Chat bleibt für anderen Teilnehmer sichtbar.")
        }
    }
    
    private func formatDateTime(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isToday(date) {
            formatter.dateFormat = "HH:mm"
            return "Heute \(formatter.string(from: date))"
        } else if calendar.isYesterday(date) {
            formatter.dateFormat = "HH:mm"
            return "Gestern \(formatter.string(from: date))"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE HH:mm"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "dd.MM.yyyy\nHH:mm"
            return formatter.string(from: date)
        }
    }
}
