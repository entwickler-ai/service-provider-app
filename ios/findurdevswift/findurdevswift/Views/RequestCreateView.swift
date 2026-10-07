//
//  RequestCreateView.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import SwiftUI

struct RequestCreateView: View {
    let service: Service
    let providerId: String
    let providerName: String
    
    @StateObject private var vm = RequestViewModel()
    @Environment(\.dismiss) var dismiss

    @State private var budgetError = ""
    @State private var isValidBudget = true
    
    @State private var title = ""
    @State private var description = ""
    @State private var budget = ""
    @State private var timeline = "1 Woche"
    @State private var requirements = ""
    @State private var showTimelinePicker = false
    
    @FocusState private var titleFocused: Bool
    @FocusState private var descriptionFocused: Bool
    @FocusState private var requirementsFocused: Bool
    @FocusState private var budgetFocused: Bool
    
    @State private var isImprovingDescription = false
    @State private var showDescriptionPreview = false
    @State private var improvedDescriptionText = ""
    @State private var originalDescriptionText = ""
    @State private var showNoImprovementAlert = false
    
    private let timelineOptions = [
        "1-2 Wochen", "3-4 Wochen", "1-2 Monate",
        "2-3 Monate", "3-6 Monate", "Flexibel"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ServiceInfoHeader()
                    
                    ProjectDetailsSection()
                    
                    BudgetTimelineSection()
                    
                    if vm.requestState.isLoading {
                        RequestLoadingCard()
                    } else {
                        SubmitButton()
                    }
                    
                    if let error = vm.requestState.error {
                        RequestErrorCard(message: error)
                    }
                    
                    if vm.requestState.isSuccess {
                        RequestSuccessCard()
                    }
                }
                .padding()
            }
            .navigationTitle("Anfrage erstellen")
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
        .onChange(of: vm.requestState.isSuccess) { _, isSuccess in
            if isSuccess {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showTimelinePicker) {
            TimelinePickerView(
                selectedTimeline: $timeline,
                options: timelineOptions,
                onDismiss: { showTimelinePicker = false }
            )
        }
        .sheet(isPresented: $showDescriptionPreview) {
            RequestAITextPreviewSheet(
                originalText: originalDescriptionText,
                improvedText: improvedDescriptionText,
                textType: "Projektbeschreibung",
                onAccept: {
                    description = improvedDescriptionText
                    showDescriptionPreview = false
                },
                onReject: {
                    showDescriptionPreview = false
                }
            )
        }
        .alert("Keine Verbesserung möglich", isPresented: $showNoImprovementAlert) {
            Button("OK") { }
        } message: {
            Text("Die Projektbeschreibung ist bereits optimal formuliert oder die KI konnte keine Verbesserungen vorschlagen.")
        }
    }
    
    private func validateBudget(_ budgetText: String) {
        if budgetText.isEmpty {
            budgetError = ""
            isValidBudget = true
            return
        }
        
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.,")
        let budgetCharacterSet = CharacterSet(charactersIn: budgetText)
        
        if !allowedCharacters.isSuperset(of: budgetCharacterSet) {
            budgetError = "Nur Zahlen und Komma/Punkt erlaubt"
            isValidBudget = false
            return
        }
        
        let normalizedBudget = budgetText.replacingOccurrences(of: ",", with: ".")
        if let budgetValue = Double(normalizedBudget), budgetValue > 0 {
            budgetError = ""
            isValidBudget = true
        } else {
            budgetError = "Bitte geben Sie ein gültiges Budget ein"
            isValidBudget = false
        }
    }
    
    @ViewBuilder
    private func ServiceInfoHeader() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Service")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(service.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("von \(providerName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func ProjectDetailsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Projektdetails")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 4) {
                if titleFocused || !title.isEmpty {
                    Text("Projekttitel")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                TextField(titleFocused || !title.isEmpty ? "z.B. E-Commerce Website für Schmuck" : "Projekttitel", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .focused($titleFocused)
            }
            .animation(.easeInOut(duration: 0.2), value: titleFocused || !title.isEmpty)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if descriptionFocused || !description.isEmpty {
                        Text("Projektbeschreibung")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    Spacer()
                    
                    Button(action: improveDescription) {
                        HStack(spacing: 4) {
                            if isImprovingDescription {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                            }
                            Text("KI verbessern")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                    }
                    .disabled(description.isEmpty || isImprovingDescription)
                }
                
                TextField(
                    descriptionFocused || !description.isEmpty
                        ? "Beschreiben Sie Ihr Projekt im Detail..."
                        : "Projektbeschreibung",
                    text: $description,
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .lineLimit(4...8)
                .focused($descriptionFocused)
            }
            .animation(.easeInOut(duration: 0.2), value: descriptionFocused || !description.isEmpty)
            
            VStack(alignment: .leading, spacing: 4) {
                if requirementsFocused || !requirements.isEmpty {
                    Text("Spezielle Anforderungen")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                TextField(requirementsFocused || !requirements.isEmpty ? "z.B. Mobile-Optimiert, Payment-Integration, etc." : "Spezielle Anforderungen", text: $requirements)
                    .textFieldStyle(.roundedBorder)
                    .focused($requirementsFocused)
            }
            .animation(.easeInOut(duration: 0.2), value: requirementsFocused || !requirements.isEmpty)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
    
    @ViewBuilder
    private func BudgetTimelineSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget & Zeitrahmen")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 4) {
                if budgetFocused || !budget.isEmpty {
                    Text("Budget (€)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                TextField(budgetFocused || !budget.isEmpty ? "z.B. 1500" : "Budget (€)", text: $budget)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .focused($budgetFocused)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isValidBudget ? Color.clear : Color.red, lineWidth: 2)
                    )
                    .onChange(of: budget) { _, newValue in
                        validateBudget(newValue)
                    }
                
                if !budgetError.isEmpty {
                    Text(budgetError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.leading, 4)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: budgetFocused || !budget.isEmpty)
            
            Button(action: {
                showTimelinePicker = true
            }) {
                HStack {
                    Text("Zeitrahmen")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(timeline)
                        .foregroundColor(.blue)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color(UIColor.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
    
    @ViewBuilder
    private func SubmitButton() -> some View {
        Button(action: submitRequest) {
            HStack {
                Image(systemName: "paperplane")
                Text("Anfrage senden")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(!isFormValid)
        .buttonStyle(PlainButtonStyle())
    }
    
    private var isFormValid: Bool {
        !title.isEmpty &&
        !description.isEmpty &&
        !budget.isEmpty &&
        isValidBudget &&
        (Double(budget.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }
    
    private func improveDescription() {
        guard !description.isEmpty else { return }
        
        isImprovingDescription = true
        originalDescriptionText = description
        
        Task {
            let improvedText = await OpenAIService.shared.enhanceProjectDescription(description)
            
            await MainActor.run {
                isImprovingDescription = false
                if let improved = improvedText, improved != description {
                    improvedDescriptionText = improved
                    showDescriptionPreview = true
                } else {
                    showNoImprovementAlert = true
                }
            }
        }
    }
    
    private func submitRequest() {
        let normalizedBudget = budget.replacingOccurrences(of: ",", with: ".")
        guard let budgetValue = Double(normalizedBudget) else { return }
        
        let requirementsList = requirements.isEmpty ? [] :
            requirements.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        vm.createRequest(
            serviceId: service.id,
            serviceTitle: service.title,
            providerId: providerId,
            providerName: providerName,
            title: title,
            description: description,
            budget: budgetValue,
            timeline: timeline,
            requirements: requirementsList
        )
    }
}

struct RequestAITextPreviewSheet: View {
    let originalText: String
    let improvedText: String
    let textType: String
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
                            
                            Text("KI-Verbesserung für \(textType)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text("Die KI hat Ihre Projektbeschreibung verbessert. Vergleichen Sie die Versionen und wählen Sie aus.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.gray)
                            
                            Text("Original \(textType)")
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
                            
                            Text("KI-verbesserte \(textType)")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        
                        Text(improvedText)
                            .padding()
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
                            RequestImprovementBulletPoint(text: "Klarere Anforderungen definiert")
                            RequestImprovementBulletPoint(text: "Professionellere Formulierung")
                            RequestImprovementBulletPoint(text: "Bessere Struktur und Details")
                            RequestImprovementBulletPoint(text: "Vollständigere Projektbeschreibung")
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Projektbeschreibung verbessern")
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

struct RequestImprovementBulletPoint: View {
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

struct TimelinePickerView: View {
    @Binding var selectedTimeline: String
    let options: [String]
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            List(options, id: \.self) { option in
                Button(action: {
                    selectedTimeline = option
                    onDismiss()
                }) {
                    HStack {
                        Text(option)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedTimeline == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Zeitrahmen wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig", action: onDismiss)
                }
            }
        }
    }
}

struct RequestLoadingCard: View {
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Anfrage wird gesendet...")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2, y: 1)
    }
}

struct RequestErrorCard: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(.red)
            Text(message)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RequestSuccessCard: View {
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle")
                .foregroundColor(.green)
            Text("Anfrage erfolgreich gesendet!")
                .foregroundColor(.green)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
