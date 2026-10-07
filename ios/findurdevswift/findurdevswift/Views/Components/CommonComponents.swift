//
//  CommonComponents.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 08.09.25.
//

import SwiftUI

struct CommonSuccessCard: View {
    let title: String
    let message: String
    let icon: String
    
    init(title: String = "Erfolgreich!", message: String, icon: String = "checkmark.circle.fill") {
        self.title = title
        self.message = message
        self.icon = icon
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .transition(.scale.combined(with: .opacity))
    }
}

struct CommonErrorCard: View {
    let title: String
    let message: String
    let retry: (() -> Void)?
    
    init(title: String = "Fehler", message: String, retry: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.retry = retry
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            
            if let retry = retry {
                Button("Erneut versuchen", action: retry)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CommonLoadingCard: View {
    let message: String
    
    init(message: String = "Lädt...") {
        self.message = message
    }
    
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text(message)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
}

struct CommonBadge: View {
    let count: Int
    
    var body: some View {
        Text(displayText)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(minWidth: 18, minHeight: 18)
            .background(Color.red)
            .clipShape(Circle())
            .scaleEffect(count > 0 ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.2), value: count)
    }
    
    private var displayText: String {
        if count > 99 {
            return "99+"
        } else {
            return "\(count)"
        }
    }
}
