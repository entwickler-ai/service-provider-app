//
//  CustomerReviewView.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 08.09.25.
//

import SwiftUI

struct CustomerReviewView: View {
    let requestId: String
    @StateObject private var viewModel = ReviewViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var rating: Int = 0
    @State private var comment: String = ""
    @State private var showSuccessMessage = false
    @State private var hasAlreadyReviewed = false
    @State private var isCheckingReview = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    if isCheckingReview {
                        VStack {
                            ProgressView()
                            Text("Bewertung wird überprüft...")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if hasAlreadyReviewed {
                        AlreadyReviewedCard()
                    } else {
                        HeaderCard()
                        
                        RatingCard(rating: $rating)
                        
                        SubmitButton(
                            isEnabled: rating > 0 && !viewModel.reviewState.isLoading,
                            isLoading: viewModel.reviewState.isLoading,
                            onSubmit: submitReview
                        )
                        
                        if let error = viewModel.reviewState.error {
                            ErrorCard(message: error)
                        }
                        
                        if showSuccessMessage {
                            ReviewSuccessCard()
                        }
                        
                        InfoCard()
                    }
                }
                .padding()
            }
            .navigationTitle("Bewertung abgeben")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            checkIfAlreadyReviewed()
        }
        .onChange(of: viewModel.reviewState.isSuccess) { _, isSuccess in
            if isSuccess {
                showSuccessMessage = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            }
        }
    }
    
    private func checkIfAlreadyReviewed() {
        guard let currentUserId = AuthService.shared.getCurrentUID() else {
            hasAlreadyReviewed = false
            isCheckingReview = false
            return
        }
        
        ReviewService.shared.hasUserReviewedRequest(requestId, currentUserId) { result in
            DispatchQueue.main.async {
                isCheckingReview = false
                switch result {
                case .success(let hasReviewed):
                    hasAlreadyReviewed = hasReviewed
                case .failure:
                    hasAlreadyReviewed = false
                }
            }
        }
    }
    
    private func submitReview() {
        viewModel.submitReview(
            requestId: requestId,
            rating: rating,
            comment: comment.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

struct AlreadyReviewedCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("Bereits bewertet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Sie haben diesen Service bereits bewertet. Jeder Service kann nur einmal bewertet werden.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct HeaderCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            Text("Wie zufrieden waren Sie?")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Ihre Bewertung hilft anderen Kunden bei der Auswahl des richtigen Dienstleisters.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RatingCard: View {
    @Binding var rating: Int
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Bewertung")
                .font(.headline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Button(action: {
                            rating = star
                        }) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 32))
                                .foregroundColor(star <= rating ? Color.yellow : Color.gray.opacity(0.3))
                                .scaleEffect(star <= rating ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.1), value: rating)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if rating > 0 {
                    Text(getRatingDescription(rating))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(getRatingColor(rating))
                        .animation(.easeInOut(duration: 0.2), value: rating)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
    
    private func getRatingDescription(_ rating: Int) -> String {
        switch rating {
        case 5: return "⭐️ Hervorragend"
        case 4: return "⭐️ Sehr gut"
        case 3: return "⭐️ Gut"
        case 2: return "⭐️ Befriedigend"
        case 1: return "⭐️ Schlecht"
        default: return ""
        }
    }
    
    private func getRatingColor(_ rating: Int) -> Color {
        switch rating {
        case 5: return .green
        case 4: return .blue
        case 3: return .orange
        case 1, 2: return .red
        default: return .gray
        }
    }
}

struct SubmitButton: View {
    let isEnabled: Bool
    let isLoading: Bool
    let onSubmit: () -> Void
    
    var body: some View {
        Button(action: onSubmit) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "paperplane.fill")
                }
                
                Text(isLoading ? "Wird gesendet..." : "Bewertung senden")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

struct ReviewSuccessCard: View {
    var body: some View {
        CommonSuccessCard(
            title: "Bewertung gesendet!",
            message: "Vielen Dank für Ihr Feedback."
        )
    }
}

struct ErrorCard: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text("Fehler")
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                
                Text("Hinweis")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            Text("• Bewertungen können nach dem Senden nicht mehr geändert werden")
            Text("• Ihre Bewertung wird öffentlich sichtbar sein")
            Text("• Konstruktives Feedback hilft Dienstleistern sich zu verbessern")
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding()
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
