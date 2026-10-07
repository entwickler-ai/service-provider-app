//
//  ErrorCard.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI

struct ErrorCardView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.red)
            
            Button("Erneut versuchen", action: retry)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
