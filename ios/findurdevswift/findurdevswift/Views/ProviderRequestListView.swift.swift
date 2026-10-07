//
//  ProviderRequestListView.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 12.09.25.
//

import SwiftUI

struct ProviderRequestListView: View {
    let isProvider: Bool
    @StateObject private var vm = RequestViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedFilter: RequestStatusFilter = .all
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProviderRequestFilterSection(
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
                    EmptyProviderRequestsView(filter: selectedFilter)
                } else {
                    ProviderRequestsList()
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
        .onDisappear {
            NotificationCenter.default.post(name: NSNotification.Name("RequestListViewed"), object: nil)
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
    private func ProviderRequestsList() -> some View {
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
                    NavigationLink(destination: ProviderRequestDetailView(request: request)) {
                        ProviderRequestCard(request: request, isProvider: isProvider)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    @ViewBuilder
    private func EmptyProviderRequestsView(filter: RequestStatusFilter) -> some View {
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
        case .all: return "Sie haben noch keine Anfragen erhalten."
        case .pending: return "Keine Anfragen warten auf Ihre Antwort."
        case .accepted: return "Keine Anfragen wurden von Ihnen angenommen."
        case .rejected: return "Keine Anfragen wurden von Ihnen abgelehnt."
        case .inProgress: return "Keine Anfragen sind in Bearbeitung."
        case .completed: return "Keine Anfragen wurden abgeschlossen."
        case .cancelled: return "Keine Anfragen wurden abgebrochen."
        }
    }
}

struct ProviderRequestFilterSection: View {
    @Binding var selectedFilter: RequestStatusFilter
    let requests: [Request]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RequestStatusFilter.allCases, id: \.self) { filter in
                    ProviderFilterChip(
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

struct ProviderFilterChip: View {
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

struct ProviderRequestDetailView: View {
    let request: Request
    @StateObject private var vm = RequestViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var showStatusPicker = false
    @State private var providerResponse = ""
    @State private var showResponseSheet = false
    @State private var isUpdating = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(request.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ProviderStatusBadge(status: vm.requestDetailState.request?.status ?? request.status)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kunde")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(.blue)
                        Text(request.customerName)
                            .foregroundColor(.blue)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Service")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Image(systemName: "briefcase")
                            .foregroundColor(.green)
                        Text(request.serviceTitle)
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
                
                if !request.requirements.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Anforderungen")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(request.requirements, id: \.self) { requirement in
                                HStack(alignment: .top) {
                                    Text("•")
                                    Text(requirement)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                
                if !request.providerResponse.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ihre Antwort")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(request.providerResponse)
                            .font(.body)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
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
                
                if vm.canProviderModifyRequest(request) {
                    VStack(spacing: 12) {
                        if request.status == .pending {
                            HStack(spacing: 12) {
                                Button("Ablehnen") {
                                    updateStatusAndDismiss(.rejected, response: "Anfrage abgelehnt")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .disabled(isUpdating)
                                
                                Button("Annehmen") {
                                    showResponseSheet = true
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .disabled(isUpdating)
                            }
                        }
                        
                        if request.status == .accepted {
                            Button("In Bearbeitung setzen") {
                                updateStatusAndDismiss(.inProgress)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .disabled(isUpdating)
                        }
                        
                        if request.status == .inProgress {
                            Button("Als abgeschlossen markieren") {
                                showResponseSheet = true
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .disabled(isUpdating)
                        }
                        
                        if isUpdating {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Wird aktualisiert...")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Anfrage Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.loadRequestDetail(request.id)
        }
        .sheet(isPresented: $showResponseSheet) {
            ProviderResponseSheet(
                request: request,
                response: $providerResponse,
                onSubmit: { response in
                    let newStatus: RequestStatus = request.status == .pending ? .accepted : .completed
                    updateStatusAndDismiss(newStatus, response: response)
                    showResponseSheet = false
                }
            )
        }
        .onChange(of: vm.requestDetailState.isUpdating) { _, isCurrentlyUpdating in
            if isUpdating && !isCurrentlyUpdating && vm.requestDetailState.error == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
            isUpdating = isCurrentlyUpdating
        }
    }
    
    private func updateStatusAndDismiss(_ newStatus: RequestStatus, response: String = "") {
        isUpdating = true
        vm.updateRequestStatus(
            requestId: request.id,
            newStatus: newStatus,
            response: response
            )
        }
    }

struct ProviderResponseSheet: View {
    let request: Request
    @Binding var response: String
    let onSubmit: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(request.status == .pending ? "Anfrage annehmen" : "Projekt abschließen")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(request.status == .pending
                     ? "Schreiben Sie eine Nachricht an den Kunden:"
                     : "Beschreiben Sie die erledigten Arbeiten:")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                TextField(
                    request.status == .pending
                        ? "Gerne übernehme ich Ihr Projekt..."
                        : "Das Projekt wurde erfolgreich abgeschlossen...",
                    text: $response,
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .lineLimit(5...10)
                
                Spacer()
                
                Button(request.status == .pending ? "Anfrage annehmen" : "Als abgeschlossen markieren") {
                    onSubmit(response)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(response.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(response.isEmpty)
            }
            .padding()
            .navigationTitle("Antwort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProviderRequestCard: View {
    let request: Request
    let isProvider: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(request.title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                ProviderStatusBadge(status: request.status)
            }
            
            HStack {
                Image(systemName: "person")
                    .foregroundColor(.blue)
                Text("Kunde: \(request.customerName)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Image(systemName: "briefcase")
                    .foregroundColor(.green)
                Text("Service: \(request.serviceTitle)")
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

struct ProviderStatusBadge: View {
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
