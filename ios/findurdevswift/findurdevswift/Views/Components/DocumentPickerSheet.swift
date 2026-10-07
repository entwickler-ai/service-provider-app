//
//  DocumentPickerSheet.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 15.09.25.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import PhotosUI

struct DocumentPickerSheet: View {
    let onFileSelected: (URL) -> Void
    let onImageSelected: (PhotosPickerItem) -> Void
    let onLinkSelected: (String, String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var showingLinkInput = false
    @State private var showingImagePicker = false
    @State private var showingFilePicker = false
    @State private var selectedImages: [PhotosPickerItem] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Anhang auswählen")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    DocumentPickerButton(
                        icon: "photo.fill",
                        title: "Bild",
                        subtitle: "Foto aus Galerie auswählen",
                        onTap: {
                            showingImagePicker = true
                        }
                    )
                    
                    DocumentPickerButton(
                        icon: "archivebox.fill",
                        title: "Datei",
                        subtitle: "PDF, ZIP oder andere Dateien",
                        onTap: {
                            showingFilePicker = true
                        }
                    )
                    
                    DocumentPickerButton(
                        icon: "link",
                        title: "Link",
                        subtitle: "Website oder URL teilen",
                        onTap: {
                            showingLinkInput = true
                        }
                    )
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Anhang")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
            .photosPicker(
                isPresented: $showingImagePicker,
                selection: $selectedImages,
                maxSelectionCount: 1,
                matching: .images
            )
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [
                    .pdf,
                    .zip,
                    .data,
                    .item,
                    .plainText,
                    .rtf,
                    .spreadsheet,
                    .presentation,
                    .database,
                    .archive,
                    .diskImage,
                    .executable,
                    .font,
                    .log,
                    .script,
                    .sourceCode,
                    .text,
                    .xml,
                    .yaml,
                    .json
                ],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
            .onChange(of: selectedImages) { _, newImages in
                if let image = newImages.first {
                    onImageSelected(image)
                    selectedImages.removeAll()
                    dismiss()
                }
            }
            .sheet(isPresented: $showingLinkInput) {
                LinkInputSheet { url, description in
                    onLinkSelected(url, description)
                    dismiss()
                }
            }
        }
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                copyFileToDocuments(from: url) { copiedURL in
                    if let copiedURL = copiedURL {
                        onFileSelected(copiedURL)
                    } else {
                        onFileSelected(url)
                    }
                    dismiss()
                }
            }
        case .failure(_):
            break
        }
    }
    
    private func copyFileToDocuments(from url: URL, completion: @escaping (URL?) -> Void) {
        guard url.startAccessingSecurityScopedResource() else {
            completion(nil)
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath.appendingPathComponent(url.lastPathComponent)
            
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.copyItem(at: url, to: destinationURL)
            completion(destinationURL)
        } catch {
            completion(nil)
        }
    }
}

struct DocumentPickerButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 1, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
