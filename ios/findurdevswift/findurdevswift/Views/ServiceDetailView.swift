//
//  ServiceDetailView.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI

struct ServiceDetailView: View {
    let service: Service
    @StateObject private var vm = ServiceViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if vm.isLoading {
                    ProgressView("Service wird geladen...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                } else if let error = vm.errorMessage {
                    ServiceErrorView(message: error, retry: {
                        vm.loadServiceDetail(service.id)
                    })
                    .padding()
                } else {
                    ServiceDetailContent(
                        service: vm.currentService ?? service,
                        provider: vm.serviceProvider,
                        isOwner: vm.isOwner
                    )
                }
            }
            .navigationTitle(service.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("")
                                .font(.body)
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                if vm.isOwner {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            NavigationLink("Bearbeiten", destination: ServiceEditView(serviceId: service.id))
                            
                            Button("Löschen", role: .destructive) {
                                showDeleteAlert = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .onAppear {
            vm.loadServiceDetail(service.id)
            setupNotificationListeners()
        }
        .onDisappear {
            removeNotificationListeners()
        }
        .onChange(of: vm.isDeleted) { _, isDeleted in
            if isDeleted {
                dismiss()
            }
        }
        .alert("Service löschen", isPresented: $showDeleteAlert) {
            Button("Löschen", role: .destructive) {
                vm.deleteService(service.id)
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Möchten Sie diesen Service wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
        }
    }
    
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ServiceUpdatedSuccessfully"),
            object: nil,
            queue: .main
        ) { notification in
            if let serviceId = notification.userInfo?["serviceId"] as? String,
               serviceId == service.id {
                vm.loadServiceDetail(service.id)
            }
        }
    }
    
    private func removeNotificationListeners() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("ServiceUpdatedSuccessfully"),
            object: nil
        )
    }
}

struct ServiceErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)

            Text(message)
                .multilineTextAlignment(.center)

            Button("Erneut versuchen", action: retry)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ServiceDetailContent: View {
    let service: Service
    let provider: UserModel?
    let isOwner: Bool
    
    var body: some View {
        LazyVStack(spacing: 20) {
            ServiceHeaderCard(service: service)
            
            if let provider = provider {
                ProviderInfoCard(provider: provider)
            }
            
            if !service.portfolioImages.isEmpty {
                ServicePortfolioImagesCard(images: service.portfolioImages)
            }
            
            DescriptionCard(description: service.description)
            
            if !service.tags.isEmpty {
                TagsCard(tags: service.tags)
            }
            
            LocationRatingCard(service: service)
            
            if !isOwner {
                CustomerActionButtons(service: service)
            }
        }
        .padding()
    }
}

struct ServiceHeaderCard: View {
    let service: Service
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(service.title)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Text("€\(Int(service.price))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ProviderInfoCard: View {
    let provider: UserModel
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: provider.profileImage)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.blue)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    }
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(provider.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                if !provider.description.isEmpty {
                    Text(provider.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if !provider.location.isEmpty {
                    HStack {
                        Image(systemName: "location")
                            .font(.caption)
                        Text(provider.location)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
}

struct ServicePortfolioImagesCard: View {
    let images: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portfolio")
                .font(.headline)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(images, id: \.self) { imageUrl in
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .overlay {
                                    ProgressView()
                                }
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
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

struct DescriptionCard: View {
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Beschreibung")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(description)
                .font(.body)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
}

struct TagsCard: View {
    let tags: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .fontWeight(.bold)
            
            FlowLayout(tags: tags)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
}

struct FlowLayout: View {
    let tags: [String]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80))
        ], alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
        }
    }
}

struct LocationRatingCard: View {
    let service: Service
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.blue)
                Text(service.location)
                    .font(.caption)
            }
            
            Spacer()
            
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                
                if let rating = service.rating, rating > 0 {
                    Text(String(format: "%.1f", rating))
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if service.reviewCount > 0 {
                        Text("(\(service.reviewCount))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Keine Bewertung")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
}

struct CustomerActionButtons: View {
    let service: Service
    
    var body: some View {
        VStack(spacing: 12) {
            NavigationLink(destination: RequestCreateView(
                service: service,
                providerId: service.providerId,
                providerName: service.providerName
            )) {
                HStack {
                    Image(systemName: "paperplane")
                        .font(.system(size: 16))
                    Text("Anfrage senden")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: ChatDetailView(
                providerId: service.providerId,
                providerName: service.providerName,
                serviceTitle: service.title
            )) {
                HStack {
                    Image(systemName: "message")
                        .font(.system(size: 16))
                    Text("Nachricht schreiben")
                        .font(.body)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
}
