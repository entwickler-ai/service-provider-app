//
//  CustomerHomeView.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI

struct CustomerHomeView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var serviceVM = ServiceViewModel()
    @StateObject private var requestVM = RequestViewModel()
    @StateObject private var chatVM = ChatViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CustomCustomerHeader(
                    requestVM: requestVM,
                    chatVM: chatVM,
                    authVM: authVM
                )
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        WelcomeCustomerHeader(
                            totalRequestUpdates: requestVM.totalRequestUpdates,
                            acceptedCount: requestVM.acceptedRequestsCount,
                            rejectedCount: requestVM.rejectedRequestsCount,
                            completedCount: requestVM.completedRequestsCount,
                            unreadMessagesCount: chatVM.totalUnreadCount
                        )
                        
                        CustomerSearchBarCard()
                        
                        CustomerPopularCategoriesCard()
                        
                        CustomerQuickActionsCard(
                            requestUpdatesCount: requestVM.totalRequestUpdates,
                            unreadMessagesCount: chatVM.totalUnreadCount
                        )
                        
                        CustomerServicesSectionHeader()
                        
                        ServicesContent()
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadData()
        }
        .refreshable {
            loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChatMessagesRead"))) { _ in
            chatVM.loadTotalUnreadCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RequestStatusChanged"))) { _ in
            requestVM.loadRequestUpdatesCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChatOpened"))) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                chatVM.loadTotalUnreadCount()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RequestUpdatesViewed"))) { _ in
            requestVM.markRequestUpdatesAsRead()
        }
    }
    
    private func loadData() {
        serviceVM.loadServices()
        requestVM.loadRequestUpdatesCount()
        chatVM.loadTotalUnreadCount()
    }
    
    @ViewBuilder
    private func ServicesContent() -> some View {
        if serviceVM.isLoading {
            HStack {
                ProgressView()
                Text("Services werden geladen...")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
        } else if let error = serviceVM.errorMessage {
            CustomerErrorCard(message: error, retry: {
                serviceVM.loadServices()
            })
        } else if serviceVM.services.isEmpty {
            CustomerEmptyServicesCard()
        } else {
            let displayServices = Array(serviceVM.services.prefix(5))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("\(displayServices.count) Services")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if displayServices.count > 2 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(displayServices) { service in
                                NavigationLink(destination: ServiceDetailView(service: service)) {
                                    CustomerServiceCard(service: service)
                                        .frame(width: max(280, UIScreen.main.bounds.width * 0.7))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.horizontal, -16)
                } else {
                    ForEach(displayServices) { service in
                        NavigationLink(destination: ServiceDetailView(service: service)) {
                            CustomerServiceCard(service: service)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

struct CustomCustomerHeader: View {
    @ObservedObject var requestVM: RequestViewModel
    @ObservedObject var chatVM: ChatViewModel
    @ObservedObject var authVM: AuthViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Kunde Dashboard")
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
                    NavigationLink(destination: CustomerRequestListView(isProvider: false)) {
                        ZStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.primary)
                                .font(.title3)
                            
                            if requestVM.totalRequestUpdates > 0 {
                                CustomerBadge(count: requestVM.totalRequestUpdates)
                                    .offset(x: 12, y: -12)
                            }
                        }
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NotificationCenter.default.post(name: NSNotification.Name("RequestUpdatesViewed"), object: nil)
                        }
                    })
                    
                    NavigationLink(destination: CustomerChatListView()) {
                        ZStack {
                            Image(systemName: "message")
                                .foregroundColor(.primary)
                                .font(.title3)
                            
                            if chatVM.totalUnreadCount > 0 {
                                CustomerBadge(count: chatVM.totalUnreadCount)
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
struct CustomerBadge: View {
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

struct CustomerErrorCard: View {
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

struct CustomerServiceCard: View {
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

struct WelcomeCustomerHeader: View {
    let totalRequestUpdates: Int
    let acceptedCount: Int
    let rejectedCount: Int
    let completedCount: Int
    let unreadMessagesCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Finden Sie den perfekten Service")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Entdecken Sie qualifizierte Dienstleister in Ihrer Nähe")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            if totalRequestUpdates > 0 {
                HStack(spacing: 8) {
                    if acceptedCount > 0 {
                        CustomerStatusUpdateChip(
                            count: acceptedCount,
                            label: "Angenommen",
                            icon: "checkmark.circle",
                            color: .green
                        )
                    }
                    
                    if rejectedCount > 0 {
                        CustomerStatusUpdateChip(
                            count: rejectedCount,
                            label: "Abgelehnt",
                            icon: "xmark.circle",
                            color: .red
                        )
                    }
                    
                    if completedCount > 0 {
                        CustomerStatusUpdateChip(
                            count: completedCount,
                            label: "Abgeschlossen",
                            icon: "checkmark.circle.fill",
                            color: .orange
                        )
                    }
                }
            }
            
            if unreadMessagesCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("\(unreadMessagesCount) neue Nachrichten")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
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

struct CustomerStatusUpdateChip: View {
    let count: Int
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text("\(count) \(label)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

struct CustomerSearchBarCard: View {
    var body: some View {
        NavigationLink(destination: ServiceListView()) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                Text("Nach Services suchen...")
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 2, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomerPopularCategoriesCard: View {
    let categories = [
        ("Webentwicklung", "globe"),
        ("Mobile Apps", "iphone"),
        ("Design", "paintbrush"),
        ("Marketing", "megaphone"),
        ("Beratung", "person.2"),
        ("Fotografie", "camera")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Beliebte Kategorien")
                .font(.headline)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.0) { category, icon in
                        NavigationLink(destination: ServiceListView(initialCategory: category)) {
                            CustomerCategoryChip(title: category, icon: icon)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 1)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
}

struct CustomerCategoryChip: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .clipShape(Capsule())
    }
}

struct CustomerQuickActionsCard: View {
    let requestUpdatesCount: Int
    let unreadMessagesCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schnellzugriff")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 8) {
                NavigationLink(destination: ServiceListView()) {
                    CustomerQuickActionButton(
                        icon: "magnifyingglass",
                        title: "Services",
                        badgeCount: 0
                    )
                }
                
                NavigationLink(destination: CustomerRequestListView(isProvider: false)) {
                    CustomerQuickActionButton(
                        icon: "doc.text",
                        title: "Anfragen",
                        badgeCount: requestUpdatesCount
                    )
                }
                
                NavigationLink(destination: CustomerChatListView()) {
                    CustomerQuickActionButton(
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

struct CustomerQuickActionButton: View {
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
                    CustomerBadge(count: badgeCount)
                        .offset(x: 12, y: -12)
                }
            }
            
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct CustomerServicesSectionHeader: View {
    var body: some View {
        HStack {
            Text("Aktuelle Services")
                .font(.title3)
                .fontWeight(.bold)
            
            Spacer()
            
            NavigationLink("Alle anzeigen", destination: ServiceListView())
                .font(.caption)
                .foregroundColor(.blue)
        }
    }
}

struct CustomerEmptyServicesCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("Keine Services verfügbar")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("Es sind noch keine Dienstleistungen verfügbar. Schauen Sie später wieder vorbei!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
}

extension CustomerHomeView {
    private func setupServiceNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ServiceUpdatedSuccessfully"),
            object: nil,
            queue: .main
        ) { _ in
            serviceVM.loadServices()
        }
    }
    
    private func removeServiceNotifications() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("ServiceUpdatedSuccessfully"),
            object: nil
        )
    }
}
