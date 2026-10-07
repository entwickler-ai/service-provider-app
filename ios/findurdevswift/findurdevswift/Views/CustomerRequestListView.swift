//
//  CustomerRequestListView.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI

struct CustomerRequestListView: View {
    let isProvider: Bool
    @StateObject private var vm = RequestViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedFilter: RequestStatusFilter = .all
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                RequestFilterSection(
                    selectedFilter: $selectedFilter,
                    requests: vm.requestState.requests
                )
                .padding(.horizontal)
                .padding(.top, 8)
                
                Divider()
                    .padding(.top, 8)
                
                if vm.requestState.isLoading {
                    ProgressView("Anfragen werden geladen...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = vm.requestState.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        
                        Text(error)
                            .multilineTextAlignment(.center)
                        
                        Button("Erneut versuchen") {
                            loadRequests()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if filteredRequests.isEmpty {
                    EmptyCustomerRequestsView(filter: selectedFilter)
                } else {
                    CustomerRequestsList()
                }
            }
            .navigationTitle("Meine Anfragen")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            loadRequests()
        }
    }
    
    private var filteredRequests: [Request] {
        let allRequests = vm.requestState.requests
        
        switch selectedFilter {
        case .all:
            return allRequests
        case .pending:
            return allRequests.filter { $0.status == .pending }
        case .accepted:
            return allRequests.filter { $0.status == .accepted }
        case .rejected:
            return allRequests.filter { $0.status == .rejected }
        case .inProgress:
            return allRequests.filter { $0.status == .inProgress }
        case .completed:
            return allRequests.filter { $0.status == .completed }
        case .cancelled:
            return allRequests.filter { $0.status == .cancelled }
        }
    }
    
    @ViewBuilder
    private func CustomerRequestsList() -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                HStack {
                    Text("\(filteredRequests.count) \(selectedFilter == .all ? "Anfragen" : selectedFilter.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                ForEach(filteredRequests) { request in
                    NavigationLink(destination: RequestDetailView(request: request)) {
                        CustomerRequestCard(request: request, isProvider: isProvider)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    @ViewBuilder
    private func EmptyCustomerRequestsView(filter: RequestStatusFilter) -> some View {
        VStack(spacing: 16) {
            Image(systemName: getEmptyStateIcon(for: filter))
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(getEmptyStateTitle(for: filter))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(getEmptyStateMessage(for: filter))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if filter == .all {
                NavigationLink(destination: ServiceListView()) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Services entdecken")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func loadRequests() {
        vm.loadUserRequests(isProvider: isProvider)
    }
    
    private func getEmptyStateIcon(for filter: RequestStatusFilter) -> String {
        switch filter {
        case .all: return "doc.text"
        case .pending: return "clock"
        case .accepted: return "checkmark.circle"
        case .rejected: return "xmark.circle"
        case .inProgress: return "gearshape.2"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    
    private func getEmptyStateTitle(for filter: RequestStatusFilter) -> String {
        switch filter {
        case .all: return "Keine Anfragen"
        case .pending: return "Keine ausstehenden Anfragen"
        case .accepted: return "Keine angenommenen Anfragen"
        case .rejected: return "Keine abgelehnten Anfragen"
        case .inProgress: return "Keine Anfragen in Bearbeitung"
        case .completed: return "Keine abgeschlossenen Anfragen"
        case .cancelled: return "Keine abgebrochenen Anfragen"
        }
    }
    
    private func getEmptyStateMessage(for filter: RequestStatusFilter) -> String {
        switch filter {
        case .all: return "Sie haben noch keine Anfragen gesendet."
        case .pending: return "Keine Anfragen warten auf eine Antwort."
        case .accepted: return "Keine Anfragen wurden angenommen."
        case .rejected: return "Keine Anfragen wurden abgelehnt."
        case .inProgress: return "Keine Anfragen sind in Bearbeitung."
        case .completed: return "Keine Anfragen wurden abgeschlossen."
        case .cancelled: return "Keine Anfragen wurden abgebrochen."
        }
    }
}

enum RequestStatusFilter: CaseIterable {
    case all, pending, accepted, rejected, inProgress, completed, cancelled
    
    var displayName: String {
        switch self {
        case .all: return "Alle"
        case .pending: return "Ausstehend"
        case .accepted: return "Angenommen"
        case .rejected: return "Abgelehnt"
        case .inProgress: return "In Bearbeitung"
        case .completed: return "Abgeschlossen"
        case .cancelled: return "Abgebrochen"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .blue
        case .pending: return .orange
        case .accepted: return .blue
        case .rejected: return .red
        case .inProgress: return .purple
        case .completed: return .green
        case .cancelled: return .gray
        }
    }
}

struct RequestFilterSection: View {
    @Binding var selectedFilter: RequestStatusFilter
    let requests: [Request]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RequestStatusFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        filter: filter,
                        count: getCount(for: filter),
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func getCount(for filter: RequestStatusFilter) -> Int {
        switch filter {
        case .all:
            return requests.count
        case .pending:
            return requests.filter { $0.status == .pending }.count
        case .accepted:
            return requests.filter { $0.status == .accepted }.count
        case .rejected:
            return requests.filter { $0.status == .rejected }.count
        case .inProgress:
            return requests.filter { $0.status == .inProgress }.count
        case .completed:
            return requests.filter { $0.status == .completed }.count
        case .cancelled:
            return requests.filter { $0.status == .cancelled }.count
        }
    }
}

struct FilterChip: View {
    let filter: RequestStatusFilter
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(filter.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                
                if count > 0 {
                    Text("(\(count))")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? filter.color : Color.gray.opacity(0.1)
            )
            .foregroundColor(
                isSelected ? .white : (count > 0 ? filter.color : .secondary)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RequestDetailView: View {
    let request: Request
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(request.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    CustomerStatusBadge(status: request.status)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Service")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Image(systemName: "briefcase")
                            .foregroundColor(.blue)
                        Text(request.serviceTitle)
                            .foregroundColor(.blue)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Anbieter")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(.green)
                        Text(request.providerName)
                            .foregroundColor(.green)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Beschreibung")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(request.description)
                        .font(.body)
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Budget")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("€\(Int(request.budget))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Zeitrahmen")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text(request.timeline)
                            .font(.body)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Erstellt: \(request.formattedCreatedAt)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if request.wasRecentlyUpdated {
                        Text("Aktualisiert: \(request.formattedUpdatedAt)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Anfrage Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CustomerRequestCard: View {
    let request: Request
    let isProvider: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(request.title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                CustomerStatusBadge(status: request.status)
            }
            
            HStack {
                Image(systemName: "briefcase")
                    .foregroundColor(.blue)
                Text(request.serviceTitle)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Image(systemName: "person")
                    .foregroundColor(.green)
                Text("Anbieter: \(request.providerName)")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            Text(request.description)
                .font(.body)
                .lineLimit(3)
            
            HStack {
                Text("Budget: €\(Int(request.budget))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Erstellt: \(formatShortDate(request.createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if request.wasRecentlyUpdated {
                        Text("Aktualisiert: \(formatShortDate(request.updatedAt))")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if request.status == .completed && !isProvider {
                HStack {
                    Spacer()
                    NavigationLink(destination: CustomerReviewView(requestId: request.id)) {
                        HStack(spacing: 4) {
                            Image(systemName: "star")
                            Text("Bewerten")
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.yellow.opacity(0.1))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
    
    private func formatShortDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = DateFormatter()
        
        let calendar = Calendar.current
        if calendar.isToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isYesterday(date) {
            return "Gestern"
        } else {
            formatter.dateFormat = "dd.MM"
            return formatter.string(from: date)
        }
    }
}

struct CustomerStatusBadge: View {
    let status: RequestStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption)
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(getStatusColor(status).opacity(0.1))
        .foregroundColor(getStatusColor(status))
        .clipShape(Capsule())
    }
    
    private func getStatusColor(_ status: RequestStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .accepted:
            return .blue
        case .rejected:
            return .red
        case .inProgress:
            return .purple
        case .completed:
            return .green
        case .cancelled:
            return .gray
        }
    }
}
