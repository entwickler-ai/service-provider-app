//
//  LinkInputSheet.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 15.09.25.
//

import SwiftUI

struct LinkInputSheet: View {
    @State private var linkText = ""
    @State private var descriptionText = ""
    @Environment(\.dismiss) var dismiss
    
    let onLinkSelected: (String, String) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Link teilen")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("URL")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("URL eingeben", text: $linkText)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Beschreibung (optional)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Link-Beschreibung", text: $descriptionText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Link hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Senden") {
                        let cleanLink = linkText.trimmingCharacters(in: .whitespacesAndNewlines)
                        let description = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
                        onLinkSelected(cleanLink, description)
                        dismiss()
                    }
                    .disabled(linkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
