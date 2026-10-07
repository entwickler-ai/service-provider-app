//
//  ServiceEditView.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI
import PhotosUI

struct ServiceEditView: View {
    let serviceId: String
    @StateObject private var vm = ServiceViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var price = ""
    @State private var tags = ""
    @State private var location = ""
    @State private var existingImages: [String] = []
    @State private var newSelectedPhotos: [PhotosPickerItem] = []
    @State private var showPhotoPicker = false
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if vm.isLoading {
                    loadingContent
                } else if let error = vm.errorMessage {
                    errorContent(error)
                } else if vm.currentService != nil {
                    mainContent
                }
            }
            .navigationTitle("Service bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            })
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $newSelectedPhotos,
            maxSelectionCount: maxPhotoCount,
            matching: .images
        )
        .onAppear {
            vm.loadServiceDetail(serviceId)
        }
        .onChange(of: vm.currentService) { _, service in
            if let service = service {
                loadServiceData(service)
            }
        }
        .onChange(of: vm.isSuccess) { _, isSuccess in
            if isSuccess {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ServiceUpdatedSuccessfully"),
                    object: nil,
                    userInfo: ["serviceId": serviceId]
                )
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            }
        }
    }
    
    private var maxPhotoCount: Int {
        5 - existingImages.count
    }
    
    private var loadingContent: some View {
        VStack {
            ProgressView()
            Text("Service wird geladen...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private func errorContent(_ error: String) -> some View {
        ServiceEditErrorView(message: error, retry: {
            vm.loadServiceDetail(serviceId)
        })
        .padding()
    }
    
    private var mainContent: some View {
        VStack(spacing: 20) {
            providerInfoSection
            serviceInfoSection
            portfolioSection
            saveButtonSection
            errorSection
        }
        .padding()
    }
    
    @ViewBuilder
    private var providerInfoSection: some View {
        if let provider = vm.serviceProvider {
            ServiceEditProviderInfoCard(provider: provider)
        }
    }
    
    private var serviceInfoSection: some View {
        ServiceEditInfoCard(
            title: $title,
            description: $description,
            price: $price,
            tags: $tags,
            location: $location
        )
    }
    
    private var portfolioSection: some View {
        ServiceEditPortfolioImagesCard(
            existingImages: $existingImages,
            newSelectedPhotos: $newSelectedPhotos,
            showPhotoPicker: $showPhotoPicker,
            onDeleteExistingImage: handleDeleteImage
        )
    }
    
    @ViewBuilder
    private var saveButtonSection: some View {
        if isSaving {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Änderungen werden gespeichert...")
                    .foregroundColor(.secondary)
            }
            .padding()
        } else {
            Button("Änderungen speichern") {
                saveChanges()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .disabled(!isFormValid)
        }
    }
    
    @ViewBuilder
    private var errorSection: some View {
        if let error = vm.errorMessage {
            ServiceEditErrorView(message: error, retry: { })
        }
    }
    
    private func handleDeleteImage(_ imageUrl: String) {
        vm.deleteServiceImage(imageUrl)
        existingImages.removeAll { $0 == imageUrl }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty &&
        !description.isEmpty &&
        !price.isEmpty &&
        !location.isEmpty &&
        (Double(price) ?? 0) > 0
    }
    
    private func loadServiceData(_ service: Service) {
        title = service.title
        description = service.description
        price = String(format: "%.0f", service.price)
        tags = service.tags.joined(separator: ", ")
        location = service.location
        existingImages = service.portfolioImages
    }
    
    private func saveChanges() {
        let priceDouble = Double(price) ?? 0.0
        let tagList = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        isSaving = true
        
        vm.updateService(
            serviceId: serviceId,
            title: title,
            description: description,
            price: priceDouble,
            tags: tagList,
            location: location,
            existingImages: existingImages,
            newImages: newSelectedPhotos
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
        }
    }
}

struct ServiceEditErrorView: View {
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

struct ServiceEditProviderInfoCard: View {
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
                
                Text("Ihr Profilbild")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ServiceEditInfoCard: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var price: String
    @Binding var tags: String
    @Binding var location: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Service-Informationen")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                TextField("Service-Titel", text: $title)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Beschreibung", text: $description, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...5)
                
                TextField("Preis (€)", text: $price)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                
                TextField("Tags (kommagetrennt)", text: $tags)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Standort", text: $location)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
}

struct ServiceEditPortfolioImagesCard: View {
    @Binding var existingImages: [String]
    @Binding var newSelectedPhotos: [PhotosPickerItem]
    @Binding var showPhotoPicker: Bool
    let onDeleteExistingImage: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Portfolio-Bilder")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Bilder hinzufügen") {
                    showPhotoPicker = true
                }
                .buttonStyle(.bordered)
                .disabled((existingImages.count + newSelectedPhotos.count) >= 5)
            }
            
            Text("\(existingImages.count + newSelectedPhotos.count)/5 Bilder")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !existingImages.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vorhandene Bilder")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(existingImages, id: \.self) { imageUrl in
                            ServiceEditExistingImageItem(
                                imageUrl: imageUrl,
                                onDelete: {
                                    onDeleteExistingImage(imageUrl)
                                }
                            )
                        }
                    }
                }
            }
            
            if !newSelectedPhotos.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Neue Bilder")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(Array(newSelectedPhotos.enumerated()), id: \.offset) { index, photo in
                            ServiceEditNewImageItem(
                                photo: photo,
                                onRemove: {
                                    newSelectedPhotos.remove(at: index)
                                }
                            )
                        }
                    }
                }
            }
            
            if existingImages.isEmpty && newSelectedPhotos.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 120)
                    .overlay {
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                            Text("Keine Bilder vorhanden")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                    }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
}

struct ServiceEditExistingImageItem: View {
    let imageUrl: String
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ZStack {
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
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { showDeleteConfirmation = true }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.red))
                    }
                    .padding(4)
                }
                Spacer()
            }
        }
        .alert("Bild löschen", isPresented: $showDeleteConfirmation) {
            Button("Löschen", role: .destructive, action: onDelete)
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Möchten Sie dieses Bild wirklich entfernen?")
        }
    }
}

struct ServiceEditNewImageItem: View {
    let photo: PhotosPickerItem
    let onRemove: () -> Void
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 100)
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ProgressView()
            }
            
            VStack {
                HStack {
                    Text("NEU")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    Spacer()
                    
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Color.red, in: Circle())
                    }
                }
                .padding(4)
                Spacer()
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        do {
            if let data = try await photo.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.image = uiImage
                    }
                }
            }
        } catch {
            print("Fehler beim Laden des Bildes: \(error)")
        }
    }
}
