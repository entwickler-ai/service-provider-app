//
//  Badge.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI

struct Badge: View {
    let count: Int
    
    var body: some View {
        Text(displayText)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, count > 9 ? 6 : 4)
            .padding(.vertical, 2)
            .background(Color.red)
            .clipShape(Capsule())
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

struct BadgedIcon: View {
    let systemName: String
    let badgeCount: Int
    let color: Color
    
    init(_ systemName: String, badgeCount: Int = 0, color: Color = .primary) {
        self.systemName = systemName
        self.badgeCount = badgeCount
        self.color = color
    }
    
    var body: some View {
        ZStack {
            Image(systemName: systemName)
                .foregroundColor(color)
            
            if badgeCount > 0 {
                Badge(count: badgeCount)
                    .offset(x: 10, y: -10)
            }
        }
    }
}
