//
//  ProfileView.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var description = ""
    @State private var location = ""
    @State private var role = ""
    @State private var profileImageUrl = ""
    @State private var showImagePicker = false
    @State private var showImageDialog = false
    @State private var selectedPhoto: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if vm.isLoading {
                    loadingView
                } else if let error = vm.errorMessage {
                    ErrorView(
                        message: error,
                        onRetry: { vm.loadUserProfile() }
                    )
                    .padding()
                } else {
                    mainContentView
                }
            }
            .navigationTitle("Mein Profil")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    backButton
                }
                
                if vm.isSuccess {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Fertig") {
                            vm.resetState()
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            vm.loadUserProfile()
            vm.setupNotificationListeners()
        }
        .onChange(of: vm.currentUser) { _, newUser in
            updateUserData(newUser)
        }
        .onChange(of: vm.isSuccess) { _, isSuccess in
            handleSuccessState(isSuccess)
        }
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $selectedPhoto,
            matching: .images
        )
        .onChange(of: selectedPhoto) { _, newPhoto in
            if let newPhoto = newPhoto {
                vm.uploadProfileImage(from: newPhoto)
            }
        }
        .alert("Profilbild", isPresented: $showImageDialog) {
            imageDialogButtons
        } message: {
            imageDialogMessage
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Profil wird geladen...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var mainContentView: some View {
        VStack(spacing: 20) {
            ProfileHeaderCard(
                name: name,
                email: email,
                role: role,
                profileImageUrl: profileImageUrl,
                isUploadingImage: vm.isUploadingImage,
                onImageTap: { showImageDialog = true }
            )
            
            PersonalInfoCard(
                name: $name,
                email: email,
                location: $location,
                description: $description,
                role: role
            )
            
            if role == "provider" {
                ProviderStatsCard(viewModel: vm)
            }
            
            actionButtonView
            
            if vm.isSuccess {
                SuccessCard()
            }
        }
        .padding()
    }
    
    private var actionButtonView: some View {
        Group {
            if vm.isUpdating {
                UpdatingCard()
            } else {
                SaveButton(
                    isEnabled: !name.isEmpty,
                    onSave: {
                        vm.updateUserProfile(
                            name: name,
                            description: description,
                            location: location
                        )
                    }
                )
            }
        }
    }
    
    private var backButton: some View {
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
    
    @ViewBuilder
    private var imageDialogButtons: some View {
        Button(profileImageUrl.isEmpty ? "Hinzufügen" : "Ändern") {
            showImagePicker = true
        }
        
        if !profileImageUrl.isEmpty {
            Button("Löschen", role: .destructive) {
                vm.deleteProfileImage()
            }
        }
        
        Button("Abbrechen", role: .cancel) { }
    }
    
    private var imageDialogMessage: Text {
        Text(profileImageUrl.isEmpty
             ? "Möchten Sie ein Profilbild hinzufügen?"
             : "Was möchten Sie mit Ihrem Profilbild machen?")
    }
    
    private func updateUserData(_ newUser: UserModel?) {
        if let user = newUser {
            name = user.name
            email = user.email
            description = user.description
            location = user.location
            role = user.role
            profileImageUrl = user.profileImage
        }
    }
    
    private func handleSuccessState(_ isSuccess: Bool) {
        if isSuccess {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                vm.resetState()
                dismiss()
            }
        }
    }
}

struct ProfileHeaderCard: View {
    let name: String
    let email: String
    let role: String
    let profileImageUrl: String
    let isUploadingImage: Bool
    let onImageTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            profileImageView
            profileInfoView
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var profileImageView: some View {
        ZStack {
            if profileImageUrl.isEmpty {
                defaultProfileImage
            } else {
                AsyncProfileImage(imageUrl: profileImageUrl)
            }
            
            if isUploadingImage {
                uploadingOverlay
            } else {
                editButton
            }
        }
    }
    
    private var defaultProfileImage: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 80, height: 80)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
    }
    
    private var uploadingOverlay: some View {
        Circle()
            .fill(Color.black.opacity(0.5))
            .frame(width: 80, height: 80)
            .overlay {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
    }
    
    private var editButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: onImageTap) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                        .background(Color.white, in: Circle())
                }
            }
            Spacer()
        }
        .frame(width: 80, height: 80)
    }
    
    private var profileInfoView: some View {
        VStack(spacing: 4) {
            Text(name.isEmpty ? "Kein Name" : name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(email)
                .font(.body)
                .foregroundColor(.secondary)
            
            Text(getRoleDisplayName(role))
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .clipShape(Capsule())
        }
    }
    
    private func getRoleDisplayName(_ role: String) -> String {
        switch role {
        case "provider": return "Dienstleister"
        case "customer": return "Kunde"
        default: return "Benutzer"
        }
    }
}

struct AsyncProfileImage: View {
    let imageUrl: String
    
    var body: some View {
        AsyncImage(url: URL(string: imageUrl)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .overlay {
                    ProgressView()
                }
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
    }
}

struct PersonalInfoCard: View {
    @Binding var name: String
    let email: String
    @Binding var location: String
    @Binding var description: String
    let role: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Persönliche Informationen")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                nameField
                emailField
                locationField
                descriptionField
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
    
    private var nameField: some View {
        HStack {
            Image(systemName: "person")
                .foregroundColor(.blue)
                .frame(width: 20)
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    private var emailField: some View {
        HStack {
            Image(systemName: "envelope")
                .foregroundColor(.blue)
                .frame(width: 20)
            TextField("E-Mail", text: .constant(email))
                .textFieldStyle(.roundedBorder)
                .disabled(true)
                .foregroundColor(.secondary)
        }
    }
    
    private var locationField: some View {
        HStack {
            Image(systemName: "location")
                .foregroundColor(.blue)
                .frame(width: 20)
            TextField("Standort (z.B. Berlin, Deutschland)", text: $location)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                Text(role == "provider" ? "Über mich / Services" : "Über mich")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            TextField(
                role == "provider"
                    ? "Beschreiben Sie Ihre Fähigkeiten und Dienstleistungen..."
                    : "Erzählen Sie etwas über sich...",
                text: $description,
                axis: .vertical
            )
            .textFieldStyle(.roundedBorder)
            .lineLimit(3...6)
        }
    }
}

struct ProviderStatsCard: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            
            if let statsError = viewModel.statsError {
                errorView(statsError)
            } else {
                statsView
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
        .onAppear {
            viewModel.loadProviderRating()
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Statistiken")
                .font(.headline)
                .fontWeight(.bold)
            
            Spacer()
            
            if viewModel.isLoadingStats {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }
    
    private func errorView(_ error: String) -> some View {
        Text(error)
            .font(.caption)
            .foregroundColor(.red)
            .multilineTextAlignment(.center)
    }
    
    private var statsView: some View {
        HStack(spacing: 20) {
            StatItem(
                icon: "briefcase",
                label: "Services",
                value: "\(viewModel.servicesCount)"
            )
            
            Spacer()
            
            StatItem(
                icon: "star.fill",
                label: "Bewertung",
                value: viewModel.averageRating > 0.0
                    ? String(format: "%.1f", viewModel.averageRating)
                    : "0"
            )
            
            Spacer()
            
            StatItem(
                icon: "person.2.fill",
                label: "Aktive Kunden",
                value: "\(viewModel.activeRequestsCount)"
            )
        }
    }
}
struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SaveButton: View {
    let isEnabled: Bool
    let onSave: () -> Void
    
    var body: some View {
        Button(action: onSave) {
            HStack {
                Image(systemName: "checkmark")
                Text("Profil speichern")
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

struct UpdatingCard: View {
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Profil wird gespeichert...")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
}

struct SuccessCard: View {
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Profil erfolgreich gespeichert!")
                .fontWeight(.medium)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .foregroundColor(.green)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.red)
            
            Button("Erneut versuchen", action: onRetry)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
