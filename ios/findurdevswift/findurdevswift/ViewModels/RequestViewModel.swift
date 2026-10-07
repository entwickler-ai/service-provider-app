//
//  RequestViewModel.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation
import SwiftUI
import Combine

final class RequestViewModel: ObservableObject {
    @Published var requestState = RequestState()
    @Published var requestDetailState = RequestDetailState()
    
    @Published var pendingRequestsCount = 0
    @Published var acceptedRequestsCount = 0
    @Published var rejectedRequestsCount = 0
    @Published var completedRequestsCount = 0
    
    @Published var shouldShowReviewPrompt = false
    
    private let requestService = RequestService.shared
    private let authService = AuthService.shared
    private let chatService = ChatService.shared
    private let openAIService = OpenAIService.shared
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let lastCheckedKey = "last_checked_request_updates"
    
    var currentUserId: String {
        return authService.getCurrentUID() ?? ""
    }
    
    var totalRequestUpdates: Int {
        acceptedRequestsCount + rejectedRequestsCount + completedRequestsCount
    }
    
    var totalPendingRequests: Int {
        pendingRequestsCount
    }
    
    func createRequest(
        serviceId: String,
        serviceTitle: String,
        providerId: String,
        providerName: String,
        title: String,
        description: String,
        budget: Double,
        timeline: String,
        requirements: [String]
    ) {
        guard !currentUserId.isEmpty else {
            requestState = RequestState.error("Benutzer nicht angemeldet")
            return
        }
        
        requestState = RequestState.loading
        
        authService.fetchUser(uid: currentUserId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    let request = Request(
                        serviceId: serviceId,
                        serviceTitle: serviceTitle,
                        providerId: providerId,
                        providerName: providerName,
                        customerId: self?.currentUserId ?? "",
                        customerName: user.name,
                        title: title,
                        description: description,
                        budget: budget,
                        timeline: timeline,
                        requirements: requirements
                    )
                    
                    self?.performCreateRequest(request, currentUser: user)
                    
                case .failure(let error):
                    self?.requestState = RequestState.error(error.localizedDescription)
                }
            }
        }
    }
    
    init() {
        setupNotificationListeners()
    }
    
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RequestUpdatesViewed"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.markRequestUpdatesAsRead()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RequestListViewed"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadPendingRequestsCount(isProvider: true)
        }
    }
    
    private func performCreateRequest(_ request: Request, currentUser: UserModel) {
        requestService.createRequest(request) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let requestId):
                    self?.createChatForRequest(request: request, currentUser: currentUser, requestId: requestId)
                    
                case .failure(let error):
                    self?.requestState = RequestState.error(error.localizedDescription)
                }
            }
        }
    }
    
    private func createChatForRequest(request: Request, currentUser: UserModel, requestId: String) {
        chatService.createOrGetChat(
            currentUserId: currentUserId,
            otherUserId: request.providerId,
            serviceId: request.serviceId,
            serviceTitle: request.serviceTitle
        ) { [weak self] chatResult in
            DispatchQueue.main.async {
                switch chatResult {
                case .success(let chat):
                    let initialMessage = """
                    Neue Service-Anfrage

                    Projekt: \(request.title)
                    Budget: €\(Int(request.budget))
                    Zeitrahmen: \(request.timeline)
                    Service: \(request.serviceTitle)

                    Beschreibung:
                    \(request.description)
                    
                    \(request.requirements.isEmpty ? "" : "\nAnforderungen:\n" + request.requirements.map { "• \($0)" }.joined(separator: "\n"))
                    """
                    
                    self?.chatService.sendMessage(
                        chatId: chat.id,
                        senderId: self?.currentUserId ?? "",
                        senderName: currentUser.name,
                        content: initialMessage
                    ) { messageResult in
                        DispatchQueue.main.async {
                            switch messageResult {
                            case .success:
                                self?.requestState = RequestState.success
                                
                            case .failure(_):
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    self?.retrySendInitialMessage(
                                        chatId: chat.id,
                                        message: initialMessage,
                                        senderName: currentUser.name
                                    )
                                }
                                self?.requestState = RequestState.success
                            }
                        }
                    }
                    
                case .failure(_):
                    self?.requestState = RequestState.success
                }
            }
        }
    }

    private func retrySendInitialMessage(chatId: String, message: String, senderName: String) {
        chatService.sendMessage(
            chatId: chatId,
            senderId: currentUserId,
            senderName: senderName,
            content: message
        ) { result in
            switch result {
            case .success:
                break
            case .failure(_):
                break
            }
        }
    }
    
    func loadUserRequests(isProvider: Bool = false) {
        guard !currentUserId.isEmpty else {
            requestState = RequestState.error("Benutzer nicht angemeldet")
            return
        }
        
        requestState = RequestState.loading
        
        let publisher = isProvider ?
            requestService.getProviderRequests(providerId: currentUserId) :
            requestService.getCustomerRequests(customerId: currentUserId)
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.requestState = RequestState.error(error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] requests in
                    self?.requestState = RequestState.success(requests: requests)
                }
            )
            .store(in: &cancellables)
    }
    
    func loadRequestsByStatus(_ status: RequestStatus, isProvider: Bool = false) {
        guard !currentUserId.isEmpty else {
            requestState = RequestState.error("Benutzer nicht angemeldet")
            return
        }
        
        requestState = RequestState.loading
        
        requestService.getRequestsByStatus(userId: currentUserId, isProvider: isProvider, status: status)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.requestState = RequestState.error(error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] requests in
                    self?.requestState = RequestState.success(requests: requests)
                }
            )
            .store(in: &cancellables)
    }
    
    func loadRequestDetail(_ requestId: String) {
        requestDetailState = RequestDetailState.loading
        
        requestService.getRequestById(requestId: requestId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let request):
                    if let request = request {
                        self?.requestDetailState = RequestDetailState(request: request)
                        self?.loadRequestHistory(requestId: requestId)
                        self?.checkForReviewPrompt(request: request)
                    } else {
                        self?.requestDetailState = RequestDetailState.error("Anfrage nicht gefunden")
                    }
                    
                case .failure(let error):
                    self?.requestDetailState = RequestDetailState.error(error.localizedDescription)
                }
            }
        }
    }
    
    private func loadRequestHistory(requestId: String) {
        requestService.getRequestHistory(requestId: requestId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let history):
                    if let currentRequest = self?.requestDetailState.request {
                        self?.requestDetailState = RequestDetailState(
                            request: currentRequest,
                            statusHistory: history
                        )
                    }
                    
                case .failure(_):
                    break
                }
            }
        }
    }
    
    func updateRequestStatus(
        requestId: String,
        newStatus: RequestStatus,
        response: String = ""
    ) {
        requestDetailState = RequestDetailState(
            isLoading: requestDetailState.isLoading,
            request: requestDetailState.request,
            statusHistory: requestDetailState.statusHistory,
            error: nil,
            isUpdating: true
        )
        
        requestService.updateRequestStatus(
            requestId: requestId,
            newStatus: newStatus,
            response: response,
            updatedBy: currentUserId
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.loadRequestDetail(requestId)
                    
                case .failure(let error):
                    self?.requestDetailState = RequestDetailState(
                        isLoading: self?.requestDetailState.isLoading ?? false,
                        request: self?.requestDetailState.request,
                        statusHistory: self?.requestDetailState.statusHistory ?? [],
                        error: error.localizedDescription,
                        isUpdating: false
                    )
                }
            }
        }
    }
    
    func deleteRequest(_ requestId: String) {
        requestDetailState = RequestDetailState(
            isLoading: requestDetailState.isLoading,
            request: requestDetailState.request,
            statusHistory: requestDetailState.statusHistory,
            error: nil,
            isUpdating: true
        )
        
        requestService.deleteRequest(requestId: requestId, userId: currentUserId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.requestDetailState = RequestDetailState()
                    self?.loadUserRequests(isProvider: false)
                    
                case .failure(let error):
                    self?.requestDetailState = RequestDetailState(
                        isLoading: self?.requestDetailState.isLoading ?? false,
                        request: self?.requestDetailState.request,
                        statusHistory: self?.requestDetailState.statusHistory ?? [],
                        error: error.localizedDescription,
                        isUpdating: false
                    )
                }
            }
        }
    }
    
    func loadPendingRequestsCount(isProvider: Bool) {
        guard !currentUserId.isEmpty else { return }
        
        if isProvider {
            requestService.getPendingRequestsCount(providerId: currentUserId) { [weak self] result in
                DispatchQueue.main.async {
                    if let count = result.getOrNull() {
                        self?.pendingRequestsCount = count
                    }
                }
            }
        } else {
            loadRequestUpdatesCount()
        }
    }
    
    func loadRequestUpdatesCount() {
        guard !currentUserId.isEmpty else { return }
        
        let lastChecked = getLastCheckedTimestamp()
        
        requestService.getRequestUpdates(customerId: currentUserId, since: lastChecked) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (accepted, rejected, completed)):
                    self?.acceptedRequestsCount = accepted
                    self?.rejectedRequestsCount = rejected
                    self?.completedRequestsCount = completed
                    
                case .failure(_):
                    break
                }
            }
        }
    }
    
    func markRequestUpdatesAsRead() {
        let currentTime = Int64(Date().timeIntervalSince1970 * 1000)
        userDefaults.set(currentTime, forKey: "\(lastCheckedKey)_\(currentUserId)")
        
        acceptedRequestsCount = 0
        rejectedRequestsCount = 0
        completedRequestsCount = 0
    }
    
    private func getLastCheckedTimestamp() -> Int64 {
        return userDefaults.object(forKey: "\(lastCheckedKey)_\(currentUserId)") as? Int64 ?? 0
    }
    
    private func checkForReviewPrompt(request: Request) {
        guard request.status == .completed,
              request.customerId == currentUserId else {
            return
        }
        shouldShowReviewPrompt = true
    }
    
    func dismissReviewPrompt() {
        shouldShowReviewPrompt = false
    }
    
    func improveProjectDescription(_ description: String, completion: @escaping (String?) -> Void) {
        Task {
            let improved = await openAIService.enhanceProjectDescription(description)
            await MainActor.run {
                completion(improved)
            }
        }
    }
    
    func optimizeRequestTitle(_ title: String, completion: @escaping (String?) -> Void) {
        Task {
            let optimized = await openAIService.improveText(title, context: "Projekt-Titel")
            await MainActor.run {
                completion(optimized)
            }
        }
    }
    
    func filterRequests(by status: RequestStatus) {
        let currentRequests = requestState.requests
        let filtered = currentRequests.filter { $0.status == status }
        requestState = RequestState.success(requests: filtered)
    }

    func searchRequests(query: String) {
        guard !query.isEmpty else { return }
        
        let currentRequests = requestState.requests
        let filtered = currentRequests.filter { request in
            request.title.localizedCaseInsensitiveContains(query) ||
            request.description.localizedCaseInsensitiveContains(query) ||
            request.serviceTitle.localizedCaseInsensitiveContains(query)
        }
        
        requestState = RequestState.success(requests: filtered)
    }
    
    func getRequestStatistics(completion: @escaping (RequestStatistics) -> Void) {
        guard !currentUserId.isEmpty else {
            completion(RequestStatistics())
            return
        }
        
        requestService.getCustomerRequests(customerId: currentUserId)
            .first()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { requests in
                    let stats = RequestStatistics(from: requests)
                    DispatchQueue.main.async {
                        completion(stats)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func resetState() {
        requestState = RequestState.idle
        requestDetailState = RequestDetailState.idle
        shouldShowReviewPrompt = false
    }
    
    func getCurrentUserRole() -> String? {
        return userDefaults.string(forKey: "current_user_role")
    }
    
    func canUserModifyRequest(_ request: Request) -> Bool {
        return request.customerId == currentUserId && request.status == .pending
    }
    
    func canProviderModifyRequest(_ request: Request) -> Bool {
        return request.providerId == currentUserId && request.status.canBeUpdatedBy(isProvider: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cancellables.removeAll()
    }
}

struct RequestStatistics {
    let totalRequests: Int
    let pendingCount: Int
    let acceptedCount: Int
    let rejectedCount: Int
    let inProgressCount: Int
    let completedCount: Int
    let cancelledCount: Int
    
    init(from requests: [Request] = []) {
        self.totalRequests = requests.count
        self.pendingCount = requests.filter { $0.status == .pending }.count
        self.acceptedCount = requests.filter { $0.status == .accepted }.count
        self.rejectedCount = requests.filter { $0.status == .rejected }.count
        self.inProgressCount = requests.filter { $0.status == .inProgress }.count
        self.completedCount = requests.filter { $0.status == .completed }.count
        self.cancelledCount = requests.filter { $0.status == .cancelled }.count
    }
    
    var successRate: Double {
        guard totalRequests > 0 else { return 0.0 }
        return Double(acceptedCount + completedCount) / Double(totalRequests)
    }
    
    var completionRate: Double {
        guard acceptedCount + inProgressCount + completedCount > 0 else { return 0.0 }
        return Double(completedCount) / Double(acceptedCount + inProgressCount + completedCount)
    }
}

extension RequestState {
    static func success(requests: [Request]) -> RequestState {
        return RequestState(requests: requests)
    }
}

extension Notification.Name {
    static let requestStatusChanged = Notification.Name("requestStatusChanged")
    static let newRequestCreated = Notification.Name("newRequestCreated")
    static let requestDeleted = Notification.Name("requestDeleted")
}
