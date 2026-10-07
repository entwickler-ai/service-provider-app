//
//  ServiceListView.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI

struct ServiceListView: View {
    @StateObject private var vm = ServiceViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedLocation = ""
    @State private var selectedCategory = ""
    @State private var minPrice = ""
    @State private var maxPrice = ""
    @State private var sortOrder = "newest"
    
    let initialCategory: String?
    
    init(initialCategory: String? = nil) {
        self.initialCategory = initialCategory
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ServiceListSearchSection(searchText: $searchText)
                    .padding()
                
                if showFilters {
                    ServiceListFilterSection(
                        selectedLocation: $selectedLocation,
                        selectedCategory: $selectedCategory,
                        minPrice: $minPrice,
                        maxPrice: $maxPrice,
                        sortOrder: $sortOrder,
                        onClearFilters: clearFilters,
                        onApplyFilters: applyFilters
                    )
                    .padding(.horizontal)
                }
                
                Divider()
                
                if vm.isLoading {
                    ServiceListLoadingView()
                } else if let error = vm.errorMessage {
                    ServiceListErrorView(message: error) {
                        vm.loadServices()
                    }
                } else if vm.services.isEmpty {
                    ServiceListEmptyStateView(hasSearch: !searchText.isEmpty)
                } else {
                    ServiceListContent()
                        .environmentObject(vm)
                }
            }
            .navigationTitle("Dienstleistungen")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(hasFilters ? .blue : .primary)
                    }
                }
            }
        }
        .onAppear {
            if let category = initialCategory {
                selectedCategory = category
            }
            vm.loadServices()
            vm.setupNotificationListeners()
            setupServiceListUpdates()
        }
        .onChange(of: searchText) { _, newValue in
            performSearch()
        }
    }
    
    private var hasFilters: Bool {
        !selectedLocation.isEmpty || !selectedCategory.isEmpty ||
        !minPrice.isEmpty || !maxPrice.isEmpty || sortOrder != "newest"
    }
    
    private func performSearch() {
        if searchText.isEmpty && !hasFilters {
            vm.loadServices()
        } else {
            vm.searchServices(
                query: searchText,
                location: selectedLocation,
                category: selectedCategory,
                minPrice: Double(minPrice),
                maxPrice: Double(maxPrice),
                sortOrder: sortOrder
            )
        }
    }
    
    private func applyFilters() {
        performSearch()
    }
    
    private func clearFilters() {
        selectedLocation = ""
        selectedCategory = ""
        minPrice = ""
        maxPrice = ""
        sortOrder = "newest"
        searchText = ""
        vm.loadServices()
    }
}

struct ServiceListSearchSection: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Services suchen...", text: $searchText)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct ServiceListFilterSection: View {
    @Binding var selectedLocation: String
    @Binding var selectedCategory: String
    @Binding var minPrice: String
    @Binding var maxPrice: String
    @Binding var sortOrder: String
    
    let onClearFilters: () -> Void
    let onApplyFilters: () -> Void
    
    let categories = ["", "Webentwicklung", "Mobile Apps", "Design", "Marketing", "Beratung", "Fotografie", "Sonstige"]
    let sortOptions = [
        ("newest", "Neueste zuerst"),
        ("oldest", "Älteste zuerst"),
        ("price_low", "Preis niedrig-hoch"),
        ("price_high", "Preis hoch-niedrig"),
        ("rating", "Beste Bewertung")
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Filter")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Zurücksetzen", action: onClearFilters)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Picker("Kategorie", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category.isEmpty ? "Alle Kategorien" : category)
                            .tag(category)
                    }
                }
                .pickerStyle(.menu)
                
                TextField("Standort", text: $selectedLocation)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    TextField("Min €", text: $minPrice)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    
                    TextField("Max €", text: $maxPrice)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
                
                Picker("Sortierung", selection: $sortOrder) {
                    ForEach(sortOptions, id: \.0) { key, label in
                        Text(label).tag(key)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
}

struct ServiceListLoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Services werden geladen...")
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ServiceListErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)

            Text(message)
                .multilineTextAlignment(.center)

            Button("Erneut versuchen", action: retry)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ServiceListEmptyStateView: View {
    let hasSearch: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("Keine Services gefunden")
                .font(.title2)
                .fontWeight(.bold)

            Text(hasSearch
                 ? "Versuchen Sie andere Suchbegriffe oder Filter."
                 : "Es sind noch keine Services verfügbar.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ServiceListContent: View {
    @EnvironmentObject private var vm: ServiceViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                HStack {
                    Text("\(vm.services.count) Services gefunden")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                ForEach(vm.services) { service in
                    NavigationLink(destination: ServiceDetailView(service: service)) {
                        ServiceListCard(service: service)
                            .padding(.horizontal)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.bottom, 20)
        }
    }
}

struct ServiceListCard: View {
    let service: Service
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(service.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                
                Spacer()
                
                HStack {
                    Image(systemName: "eurosign")
                        .font(.caption)
                    Text("\(Int(service.price))")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            Text(service.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            if !service.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(service.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        
                        if service.tags.count > 3 {
                            Text("+\(service.tags.count - 3)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .font(.caption)
                    Text(service.location)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    if let rating = service.rating, rating > 0 {
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                        
                        if service.reviewCount > 0 {
                            Text("(\(service.reviewCount))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Keine Bewertung")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
}

extension ServiceListView {
    func setupServiceListUpdates() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ReviewCreatedSuccessfully"),
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("RefreshServicesList"),
                    object: nil
                )
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ServiceUpdatedSuccessfully"),
            object: nil,
            queue: .main
        ) { _ in
            vm.loadServices()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RefreshServicesList"),
            object: nil,
            queue: .main
        ) { _ in
            vm.loadServices()
        }
    }
}
