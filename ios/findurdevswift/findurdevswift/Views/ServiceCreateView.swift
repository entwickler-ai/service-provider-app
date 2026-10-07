//
//  ServiceCreateView.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI
import PhotosUI

struct ServiceCreateView: View {
    @StateObject private var vm = ServiceViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var priceError = ""
    @State private var isValidPrice = true
    
    var onServiceCreated: (() -> Void)?
    
    @State private var title = ""
    @State private var description = ""
    @State private var price = ""
    @State private var tags = ""
    @State private var location = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showPhotoPicker = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ServiceCreateInfoCard(
                        title: $title,
                        description: $description,
                        price: $price,
                        tags: $tags,
                        location: $location,
                        priceError: $priceError,
                        isValidPrice: $isValidPrice
                    )
                    
                    ServiceCreatePortfolioCard(
                        selectedPhotos: $selectedPhotos,
                        showPhotoPicker: $showPhotoPicker
                    )
                    
                    if vm.isLoading {
                        ServiceCreateLoadingCard()
                    } else {
                        CreateButton(
                            isEnabled: isFormValid,
                            onTap: createService
                        )
                    }
                    
                    if let error = vm.errorMessage {
                        ServiceCreateErrorCard(message: error)
                    }
                    
                    if vm.isSuccess {
                        ServiceCreateSuccessCard()
                    }
                    
                    TipsCard()
                }
                .padding()
            }
            .navigationTitle("Neuen Service erstellen")
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
            }
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotos,
            maxSelectionCount: 5,
            matching: .images
        )
        .onChange(of: vm.isSuccess) { _, isSuccess in
            if isSuccess {
                onServiceCreated?()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty &&
        !description.isEmpty &&
        !price.isEmpty &&
        !location.isEmpty &&
        isValidPrice &&
        (Double(price.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }
    
    private func createService() {
        let normalizedPrice = price.replacingOccurrences(of: ",", with: ".")
        let priceDouble = Double(normalizedPrice) ?? 0.0
        let tagList = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        vm.createService(
            title: title,
            description: description,
            price: priceDouble,
            tags: tagList,
            location: location,
            selectedImages: selectedPhotos
        )
    }
}

struct ServiceCreateInfoCard: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var price: String
    @Binding var tags: String
    @Binding var location: String
    @Binding var priceError: String
    @Binding var isValidPrice: Bool
    
    @State private var isImprovingDescription = false
    
    @State private var showDescriptionPreview = false
    @State private var improvedDescriptionText = ""
    @State private var originalDescriptionText = ""
    @State private var showNoImprovementAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Service-Informationen")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                TextField("Service-Titel", text: $title)
                    .textFieldStyle(.roundedBorder)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Beschreibung")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: improveDescription) {
                            HStack(spacing: 4) {
                                if isImprovingDescription {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.caption)
                                }
                                Text("KI verbessern")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                        }
                        .disabled(description.isEmpty || isImprovingDescription)
                    }
                    
                    TextField("Beschreibung", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...5)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Preis (€)", text: $price)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isValidPrice ? Color.clear : Color.red, lineWidth: 2)
                        )
                        .onChange(of: price) { _, newValue in
                            validatePrice(newValue)
                        }
                    
                    if !priceError.isEmpty {
                        Text(priceError)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.leading, 4)
                    }
                }
                
                TextField("Tags", text: $tags)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Standort", text: $location)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
        .sheet(isPresented: $showDescriptionPreview) {
            AITextPreviewSheet(
                originalText: originalDescriptionText,
                improvedText: improvedDescriptionText,
                textType: "Beschreibung",
                onAccept: {
                    description = improvedDescriptionText
                    showDescriptionPreview = false
                },
                onReject: {
                    showDescriptionPreview = false
                }
            )
        }
        .alert("Keine Verbesserung möglich", isPresented: $showNoImprovementAlert) {
            Button("OK") { }
        } message: {
            Text("Die Beschreibung ist bereits optimal formuliert oder die KI konnte keine Verbesserungen vorschlagen.")
        }
    }
    
    private func validatePrice(_ priceText: String) {
        if priceText.isEmpty {
            priceError = ""
            isValidPrice = true
            return
        }
        
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.,")
        let priceCharacterSet = CharacterSet(charactersIn: priceText)
        
        if !allowedCharacters.isSuperset(of: priceCharacterSet) {
            priceError = "Nur Zahlen und Komma/Punkt erlaubt"
            isValidPrice = false
            return
        }
        
        let normalizedPrice = priceText.replacingOccurrences(of: ",", with: ".")
        if let priceValue = Double(normalizedPrice), priceValue > 0 {
            priceError = ""
            isValidPrice = true
        } else {
            priceError = "Bitte geben Sie einen gültigen Preis ein"
            isValidPrice = false
        }
    }
    
    private func improveDescription() {
        guard !description.isEmpty else { return }
        
        isImprovingDescription = true
        originalDescriptionText = description
        
        Task {
            let improvedText = await OpenAIService.shared.optimizeServiceDescription(description)
            
            await MainActor.run {
                isImprovingDescription = false
                if let improved = improvedText, improved != description {
                    improvedDescriptionText = improved
                    showDescriptionPreview = true
                } else {
                    showNoImprovementAlert = true
                }
            }
        }
    }
}

struct AITextPreviewSheet: View {
    let originalText: String
    let improvedText: String
    let textType: String
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                            Text("KI-Verbesserung für \(textType)")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        
                        Text("Vergleichen Sie den ursprünglichen und verbesserten Text:")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.gray)
                            Text("Original \(textType)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Text(originalText)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                            Text("KI-verbesserter \(textType)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Text(improvedText)
                            .padding()
                            .background(Color.blue.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "lightbulb")
                                .foregroundColor(.orange)
                            Text("Mögliche Verbesserungen:")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("• Professionellere Sprache")
                            Text("• Klarere Struktur")
                            Text("• Ansprechendere Formulierung")
                            Text("• Korrigierte Grammatik")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("KI-Textverbesserung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Ablehnen", action: onReject)
                        .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Annehmen", action: onAccept)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

struct ServiceCreatePortfolioCard: View {
    @Binding var selectedPhotos: [PhotosPickerItem]
    @Binding var showPhotoPicker: Bool
    
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
                .disabled(selectedPhotos.count >= 5)
            }
            
            Text("\(selectedPhotos.count)/5 Bilder ausgewählt")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if selectedPhotos.isEmpty {
                EmptyImagePlaceholder()
            } else {
                ImagePreviewGrid(selectedPhotos: $selectedPhotos)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
}

struct EmptyImagePlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.1))
            .frame(height: 120)
            .overlay {
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    Text("Noch keine Bilder hinzugefügt")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            }
    }
}

struct ImagePreviewGrid: View {
    @Binding var selectedPhotos: [PhotosPickerItem]
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3),
            spacing: 12
        ) {
            ForEach(selectedPhotos.indices, id: \.self) { index in
                PhotoPreviewItem(
                    photo: selectedPhotos[index],
                    index: index,
                    onRemove: {
                        removePhoto(at: index)
                    }
                )
                .frame(height: 60)
            }
        }
    }
    
    private func removePhoto(at index: Int) {
        guard index >= 0 && index < selectedPhotos.count else { return }
        selectedPhotos.remove(at: index)
    }
}

struct PhotoPreviewItem: View {
    let photo: PhotosPickerItem
    let index: Int
    let onRemove: () -> Void
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ProgressView()
                    .scaleEffect(1.0)
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: onRemove) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 28, height: 28)
                                .shadow(radius: 3)
                            
                            Circle()
                                .fill(Color.red)
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(8)
                }
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

struct CreateButton: View {
    let isEnabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "plus")
                Text("Service erstellen")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(!isEnabled)
    }
}

struct ServiceCreateLoadingCard: View {
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Service wird erstellt...")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
}

struct ServiceCreateErrorCard: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(.red)
            Text(message)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ServiceCreateSuccessCard: View {
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle")
                .foregroundColor(.green)
            Text("Service erfolgreich erstellt!")
                .foregroundColor(.green)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TipsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.blue)
                Text("Tipps für einen erfolgreichen Service")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                TipRow(text: "Verwenden Sie aussagekräftige Bilder")
                TipRow(text: "Beschreiben Sie Ihren Service detailliert")
                TipRow(text: "Setzen Sie einen fairen Preis")
                TipRow(text: "Nutzen Sie relevante Tags")
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack {
            Text("•")
                .foregroundColor(.blue)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
