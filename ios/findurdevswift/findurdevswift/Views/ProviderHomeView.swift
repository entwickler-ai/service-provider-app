//
//  ProviderHomeView.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI

struct ProviderHomeView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var serviceVM = ServiceViewModel()
    @StateObject private var requestVM = RequestViewModel()
    @StateObject private var chatVM = ChatViewModel()
    @State private var showingServiceCreate = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CustomProviderHeader(
                    requestVM: requestVM,
                    chatVM: chatVM,
                    authVM: authVM
                )
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        WelcomeProviderHeader(
                            pendingRequestsCount: requestVM.pendingRequestsCount,
                            unreadMessagesCount: chatVM.totalUnreadCount
                        )
                        
                        QuickActionsProviderCard(
                            pendingRequestsCount: requestVM.pendingRequestsCount,
                            unreadMessagesCount: chatVM.totalUnreadCount,
                            onServiceCreated: { loadData() }
                        )
                        
                        ProviderMyServicesSectionHeader()
                        
                        MyServicesContent()
                        
                        Color.clear.frame(height: 20)
                    }
                    .padding()
                }
                
                VStack {
                    Button(action: {
                        showingServiceCreate = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            Text("Service erstellen")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                }
                .background(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingServiceCreate) {
            ServiceCreateView(onServiceCreated: {
                loadData()
                showingServiceCreate = false
            })
        }
        .onAppear {
            loadData()
            setupServiceNotifications()
        }
        .onDisappear {
            removeServiceNotifications()
        }
        .refreshable {
            loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChatMessagesRead"))) { _ in
            chatVM.loadTotalUnreadCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RequestStatusChanged"))) { _ in
            requestVM.loadPendingRequestsCount(isProvider: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RequestListViewed"))) { _ in
            requestVM.loadPendingRequestsCount(isProvider: true)
        }
    }
    
    private func loadData() {
        serviceVM.loadServicesByProvider()
        requestVM.loadPendingRequestsCount(isProvider: true)
        chatVM.loadTotalUnreadCount()
    }
    
    private func setupServiceNotifications() {
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ServiceCreatedSuccessfully"),
                object: nil,
                queue: .main
            ) { _ in
                loadData()
            }
            
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ServiceDeletedSuccessfully"),
                object: nil,
                queue: .main
            ) { _ in
                loadData()
            }
            
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ServiceUpdatedSuccessfully"),
                object: nil,
                queue: .main
            ) { _ in
                serviceVM.loadServicesByProvider()
            }
            
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ChatOpened"),
                object: nil,
                queue: .main
            ) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    chatVM.loadTotalUnreadCount()
                }
            }
        }
        
        private func removeServiceNotifications() {
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("ServiceCreatedSuccessfully"),
                object: nil
            )
            
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("ServiceDeletedSuccessfully"),
                object: nil
            )
            
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("ServiceUpdatedSuccessfully"),
                object: nil
            )
            
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("ChatOpened"),
                object: nil
            )
        }
    
    @ViewBuilder
    private func MyServicesContent() -> some View {
        if serviceVM.isLoading {
            HStack {
                ProgressView()
                Text("Services werden geladen...")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
        } else if let error = serviceVM.errorMessage {
            ProviderErrorCard(message: error, retry: {
                serviceVM.loadServicesByProvider()
            })
        } else if serviceVM.services.isEmpty {
            ProviderEmptyServicesCard()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(serviceVM.services.count) Services")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if serviceVM.services.count > 2 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(serviceVM.services) { service in
                                NavigationLink(destination: ServiceDetailView(service: service)) {
                                    ProviderServiceCard(service: service)
                                        .frame(width: max(280, UIScreen.main.bounds.width * 0.7))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.horizontal, -16)
                } else {
                    ForEach(serviceVM.services) { service in
                        NavigationLink(destination: ServiceDetailView(service: service)) {
                            ProviderServiceCard(service: service)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

extension ProviderHomeView {
    struct CustomProviderHeader: View {
    @ObservedObject var requestVM: RequestViewModel
    @ObservedObject var chatVM: ChatViewModel
    @ObservedObject var authVM: AuthViewModel
        
        var body: some View {
            VStack(spacing: 12) {
                Text("Provider Dashboard")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if let user = authVM.currentUser {
                            Text("Hallo,")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(user.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                        } else {
                            Text("Provider")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                HStack {
                    Spacer()
                    
                    HStack(spacing: 20) {
                        NavigationLink(destination: ProviderRequestListView(isProvider: true)) {
                            ZStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.primary)
                                    .font(.title3)
                                
                                if requestVM.pendingRequestsCount > 0 {
                                    ProviderBadge(count: requestVM.pendingRequestsCount)
                                        .offset(x: 12, y: -12)
                                }
                            }
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                requestVM.loadPendingRequestsCount(isProvider: true)
                            }
                        })
                        
                        NavigationLink(destination: ProviderChatListView()) {
                            ZStack {
                                Image(systemName: "message")
                                    .foregroundColor(.primary)
                                    .font(.title3)
                                
                                if chatVM.totalUnreadCount > 0 {
                                    ProviderBadge(count: chatVM.totalUnreadCount)
                                        .offset(x: 12, y: -12)
                                }
                            }
                        }
                        .simultaneousGesture(TapGesture().onEnded { 
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                NotificationCenter.default.post(name: NSNotification.Name("ChatListViewed"), object: nil)
                            }
                        })
                        
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.circle")
                                .foregroundColor(.primary)
                                .font(.title3)
                        }
                        
                        Button(action: { authVM.logout() }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.primary)
                                .font(.title3)
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .shadow(radius: 1, y: 1)
        }
    }
    
    struct ProviderErrorCard: View {
        let message: String
        let retry: () -> Void
        
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 30))
                    .foregroundColor(.red)
                
                Text(message)
                    .multilineTextAlignment(.center)
                
                Button("Erneut versuchen", action: retry)
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    struct ProviderServiceCard: View {
        let service: Service
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(service.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "eurosign")
                            .font(.caption2)
                        Text("\(Int(service.price))")
                            .font(.callout)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                Text(service.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    HStack(spacing: 3) {
                        Image(systemName: "location")
                            .font(.caption2)
                        Text(service.location)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        
                        if let rating = service.rating, rating > 0 {
                        Text(String(format: "%.1f", rating))
                            .font(.caption2)
                        
                            if service.reviewCount > 0 {
                                Text("(\(service.reviewCount))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("Keine Bewertung")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 2, y: 1)
        }
    }
    
    struct ProviderBadge: View {
        let count: Int
        
        var body: some View {
            Text("\(count)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(minWidth: 18, minHeight: 18)
                .background(Color.red)
                .clipShape(Circle())
        }
    }
    
    struct WelcomeProviderHeader: View {
        let pendingRequestsCount: Int
        let unreadMessagesCount: Int
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Willkommen zurück!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Verwalten Sie Ihre Services und Anfragen")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                HStack(spacing: 20) {
                    ProviderStatColumn(
                        value: "\(pendingRequestsCount)",
                        label: "Offene Anfragen"
                    )
                    Spacer()
                    ProviderStatColumn(
                        value: "\(unreadMessagesCount)",
                        label: "Neue Nachrichten"
                    )
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    struct ProviderStatColumn: View {
        let value: String
        let label: String
        
        var body: some View {
            VStack(spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    struct QuickActionsProviderCard: View {
        let pendingRequestsCount: Int
        let unreadMessagesCount: Int
        let onServiceCreated: () -> Void
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Schnellaktionen")
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack(spacing: 8) {
                    NavigationLink(destination: ServiceCreateView(onServiceCreated: onServiceCreated)) {
                        ProviderQuickActionButton(
                            icon: "plus",
                            title: "Service erstellen",
                            badgeCount: 0
                        )
                    }
                    
                    NavigationLink(destination: ProviderRequestListView(isProvider: true)) {
                        ProviderQuickActionButton(
                            icon: "doc.text",
                            title: "Anfragen",
                            badgeCount: pendingRequestsCount
                        )
                    }
                    
                    NavigationLink(destination: ProviderChatListView()) {
                        ProviderQuickActionButton(
                            icon: "message",
                            title: "Nachrichten",
                            badgeCount: unreadMessagesCount
                        )
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 2, y: 1)
        }
    }
    
    struct ProviderQuickActionButton: View {
        let icon: String
        let title: String
        let badgeCount: Int
        
        var body: some View {
            VStack(spacing: 4) {
                ZStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    if badgeCount > 0 {
                        ProviderBadge(count: badgeCount)
                            .offset(x: 12, y: -12)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    struct ProviderMyServicesSectionHeader: View {
        var body: some View {
            HStack {
                Text("Meine Services")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink("Alle anzeigen", destination: ServiceListView())
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    struct ProviderEmptyServicesCard: View {
        var body: some View {
            VStack(spacing: 11) {
                Image(systemName: "briefcase")
                    .font(.system(size: 22))
                    .foregroundColor(.gray)
                
                Text("Noch keine Services")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Erstellen Sie Ihren ersten Service, um Kunden zu erreichen.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                NavigationLink(destination: ServiceCreateView()) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.caption)
                        Text("Ersten Service erstellen")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 2, y: 1)
        }
    }
}
