//
//  AITextImprovementSheet.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 15.09.25.
//

import SwiftUI

struct AITextImprovementSheet: View {
    let originalText: String
    let improvedText: String
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.orange)
                                .font(.title2)
                            
                            Text("Verbesserter Text")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text("Die KI hat Ihren Text verbessert. Vergleichen Sie die Versionen und wählen Sie aus.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.gray)
                            
                            Text("Original")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        
                        Text(originalText)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.orange)
                            
                            Text("KI-verbessert")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        
                        ScrollView {
                            Text(improvedText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .textSelection(.enabled)
                        }
                        .frame(maxHeight: 200)
                        .background(Color.orange.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb")
                                .foregroundColor(.blue)
                            
                            Text("Mögliche Verbesserungen:")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            ImprovementBulletPoint(text: "Klarere und professionellere Sprache")
                            ImprovementBulletPoint(text: "Bessere Struktur und Lesbarkeit")
                            ImprovementBulletPoint(text: "Korrigierte Grammatik und Rechtschreibung")
                            ImprovementBulletPoint(text: "Höflichere und ansprechendere Formulierung")
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Textverbesserung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Ablehnen") {
                        onReject()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Annehmen") {
                        onAccept()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

struct ImprovementBulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
                .padding(.top, 2)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct MessageSummarySheet: View {
    let message: Message?
    let summary: String
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            Text("Zusammengefasster Text")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text("Die KI hat die Nachricht für Sie zusammengefasst.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    if let message = message {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "bubble.left")
                                    .foregroundColor(.gray)
                                
                                Text("Original Nachricht")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text(formatMessageTime(message.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(message.content)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .frame(maxHeight: 150)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.blue)
                                
                                Text("Zusammenfassung")
                                    .font(.headline)
                                    .fontWeight(.medium)
                            }
                            
                            Text(summary)
                                .padding()
                                .background(Color.blue.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Nachrichtenzusammenfassung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private func formatMessageTime(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
