package com.findurdevkotlin.ui.request

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.findurdevkotlin.data.model.Request
import com.findurdevkotlin.data.model.RequestDetailState
import com.findurdevkotlin.data.model.RequestState
import com.findurdevkotlin.data.model.RequestStatus
import com.findurdevkotlin.data.repository.AuthRepository
import com.findurdevkotlin.data.repository.ChatRepository
import com.findurdevkotlin.data.repository.RequestRepository
import com.findurdevkotlin.data.repository.ReviewRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import javax.inject.Inject
import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.findurdevkotlin.data.repository.OpenAIService
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.Job

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "request_preferences")

@HiltViewModel
class RequestViewModel @Inject constructor(
    private val requestRepository: RequestRepository,
    private val authRepository: AuthRepository,
    private val chatRepository: ChatRepository,
    private val reviewRepository: ReviewRepository,
    val openAIService: OpenAIService,
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val _shouldShowReviewPrompt = MutableStateFlow(false)
    val shouldShowReviewPrompt: StateFlow<Boolean> = _shouldShowReviewPrompt

    private val _reviewPromptRequestId = MutableStateFlow("")

    private val _requestState = MutableStateFlow(RequestState())
    val requestState: StateFlow<RequestState> = _requestState

    private val _requestDetailState = MutableStateFlow(RequestDetailState())
    val requestDetailState: StateFlow<RequestDetailState> = _requestDetailState

    private val _pendingRequestsCount = MutableStateFlow(0)
    val pendingRequestsCount: StateFlow<Int> = _pendingRequestsCount

    private val _newAcceptedRequestsCount = MutableStateFlow(0)
    val newAcceptedRequestsCount: StateFlow<Int> = _newAcceptedRequestsCount

    private val _newRejectedRequestsCount = MutableStateFlow(0)
    val newRejectedRequestsCount: StateFlow<Int> = _newRejectedRequestsCount

    private val _newCompletedRequestsCount = MutableStateFlow(0)
    val newCompletedRequestsCount: StateFlow<Int> = _newCompletedRequestsCount

    private val currentUserId = authRepository.getCurrentUser()?.uid ?: ""

    private var requestsJob: Job? = null
    private var requestUpdatesJob: Job? = null
    private var pendingCountJob: Job? = null

    private val lastCheckedKey = longPreferencesKey("last_checked_request_updates_$currentUserId")

    fun createRequest(
        serviceId: String,
        serviceTitle: String,
        providerId: String,
        providerName: String,
        title: String,
        description: String,
        budget: Double,
        timeline: String,
        requirements: List<String>
    ) {
        viewModelScope.launch {
            _requestState.value = RequestState(isLoading = true)

            try {
                val currentUserResult = authRepository.getCurrentUserInfo()
                val currentUser = currentUserResult.getOrNull()

                if (currentUser == null) {
                    _requestState.value = RequestState(error = "User information not found")
                    return@launch
                }

                val request = Request(
                    serviceId = serviceId,
                    serviceTitle = serviceTitle,
                    providerId = providerId,
                    providerName = providerName,
                    customerId = currentUserId,
                    customerName = currentUser.name,
                    title = title,
                    description = description,
                    budget = budget,
                    timeline = timeline,
                    requirements = requirements
                )

                val result = requestRepository.createRequest(request)

                if (result.isSuccess) {
                    val chatResult = chatRepository.createOrGetChat(
                        currentUserId = currentUserId,
                        otherUserId = providerId,
                        serviceId = serviceId,
                        serviceTitle = serviceTitle
                    )

                    if (chatResult.isSuccess) {
                        val chat = chatResult.getOrNull()
                        if (chat != null) {
                            chatRepository.sendMessage(
                                chatId = chat.id,
                                senderId = currentUserId,
                                senderName = currentUser.name,
                                content = "Neue Anfrage gesendet: $title\n\nBudget: €${budget.toInt()}\nZeitrahmen: $timeline\n\n$description"
                            )
                        }
                    }

                    _requestState.value = RequestState(isSuccess = true)
                } else {
                    _requestState.value = RequestState(
                        error = result.exceptionOrNull()?.message ?: "Failed to create request"
                    )
                }
            } catch (e: Exception) {
                _requestState.value = RequestState(error = e.message)
            }
        }
    }

    fun loadUserRequests(isProvider: Boolean = false) {
        requestsJob?.cancel()

        requestsJob = viewModelScope.launch {
            _requestState.value = RequestState(isLoading = true)

            val requestsFlow = if (isProvider) {
                requestRepository.getProviderRequests(currentUserId)
            } else {
                requestRepository.getCustomerRequests(currentUserId)
            }

            requestsFlow
                .catch { error ->
                    _requestState.value = RequestState(error = error.message)
                }
                .collectLatest { requests ->
                    val uniqueRequests = requests
                        .distinctBy { it.id }
                        .filter { it.id.isNotEmpty() }
                        .sortedByDescending { it.createdAt }

                    _requestState.value = RequestState(requests = uniqueRequests)
                }
        }
    }

    fun loadRequestsByStatus(status: RequestStatus, isProvider: Boolean = false) {
        requestsJob?.cancel()

        requestsJob = viewModelScope.launch {
            _requestState.value = RequestState(isLoading = true)

            requestRepository.getRequestsByStatus(currentUserId, isProvider, status)
                .catch { error ->
                    _requestState.value = RequestState(error = error.message)
                }
                .collectLatest { requests ->
                    val uniqueRequests = requests
                        .distinctBy { it.id }
                        .filter { it.id.isNotEmpty() }
                        .sortedByDescending { it.updatedAt }

                    _requestState.value = RequestState(requests = uniqueRequests)
                }
        }
    }

    fun loadRequestDetail(requestId: String) {
        viewModelScope.launch {
            _requestDetailState.value = RequestDetailState(isLoading = true)

            try {
                val requestResult = requestRepository.getRequestById(requestId)
                val historyResult = requestRepository.getRequestHistory(requestId)

                if (requestResult.isSuccess) {
                    val request = requestResult.getOrNull()
                    val history = historyResult.getOrNull() ?: emptyList()

                    _requestDetailState.value = RequestDetailState(
                        request = request,
                        statusHistory = history
                    )

                    request?.let { checkForReviewPrompt(it) }

                } else {
                    _requestDetailState.value = RequestDetailState(
                        error = requestResult.exceptionOrNull()?.message
                    )
                }
            } catch (e: Exception) {
                _requestDetailState.value = RequestDetailState(error = e.message)
            }
        }
    }

    fun dismissReviewPrompt() {
        _shouldShowReviewPrompt.value = false
        _reviewPromptRequestId.value = ""
    }

    fun updateRequestStatus(
        requestId: String,
        newStatus: RequestStatus,
        response: String = ""
    ) {
        viewModelScope.launch {
            _requestDetailState.value = _requestDetailState.value.copy(isUpdating = true)

            val result = requestRepository.updateRequestStatus(
                requestId = requestId,
                newStatus = newStatus,
                response = response,
                updatedBy = currentUserId
            )

            if (result.isSuccess) {
                loadRequestDetail(requestId)
            } else {
                _requestDetailState.value = _requestDetailState.value.copy(
                    isUpdating = false,
                    error = result.exceptionOrNull()?.message
                )
            }
        }
    }

    fun deleteRequest(requestId: String) {
        viewModelScope.launch {
            _requestDetailState.value = _requestDetailState.value.copy(isUpdating = true)

            val result = requestRepository.deleteRequest(requestId, currentUserId)

            if (result.isSuccess) {
                _requestDetailState.value = RequestDetailState()
                loadUserRequests(isProvider = false)
            } else {
                _requestDetailState.value = _requestDetailState.value.copy(
                    isUpdating = false,
                    error = result.exceptionOrNull()?.message
                )
            }
        }
    }

    fun loadPendingRequestsCount(isProvider: Boolean = true) {
        if (!isProvider) return

        pendingCountJob?.cancel()

        pendingCountJob = viewModelScope.launch {
            val result = requestRepository.getPendingRequestsCount(currentUserId)
            if (result.isSuccess) {
                _pendingRequestsCount.value = result.getOrNull() ?: 0
            }
        }
    }

    fun loadRequestUpdatesCount() {
        requestUpdatesJob?.cancel()

        requestUpdatesJob = viewModelScope.launch {
            try {
                val lastChecked = getLastCheckedTimestamp()

                requestRepository.getCustomerRequests(currentUserId)
                    .catch { error ->
                    }
                    .collectLatest { requests ->
                        val uniqueRequests = requests
                            .distinctBy { it.id }
                            .filter { it.id.isNotEmpty() }

                        var acceptedCount = 0
                        var rejectedCount = 0
                        var completedCount = 0

                        uniqueRequests.forEach { request ->
                            if (request.updatedAt > lastChecked) {
                                when (request.status) {
                                    RequestStatus.ACCEPTED -> acceptedCount++
                                    RequestStatus.REJECTED -> rejectedCount++
                                    RequestStatus.COMPLETED -> completedCount++
                                    else -> { /* Ignore other statuses */ }
                                }
                            }
                        }

                        _newAcceptedRequestsCount.value = acceptedCount
                        _newRejectedRequestsCount.value = rejectedCount
                        _newCompletedRequestsCount.value = completedCount
                    }
            } catch (_: Exception) {
            }
        }
    }

    fun markRequestUpdatesAsRead() {
        viewModelScope.launch {
            try {
                val currentTime = System.currentTimeMillis()
                context.dataStore.edit { preferences ->
                    preferences[lastCheckedKey] = currentTime
                }

                _newAcceptedRequestsCount.value = 0
                _newRejectedRequestsCount.value = 0
                _newCompletedRequestsCount.value = 0
            } catch (_: Exception) {
            }
        }
    }

    private suspend fun getLastCheckedTimestamp(): Long {
        return try {
            context.dataStore.data
                .map { preferences ->
                    preferences[lastCheckedKey] ?: 0L
                }
                .first()
        } catch (_: Exception) {
            0L
        }
    }

    private suspend fun checkForReviewPrompt(request: Request) {
        if (request.status == RequestStatus.COMPLETED &&
            request.customerId == currentUserId) {

            try {
                val hasReviewed = reviewRepository.hasUserReviewedRequest(request.id, currentUserId)
                if (hasReviewed.isSuccess && !hasReviewed.getOrNull()!!) {
                    _shouldShowReviewPrompt.value = true
                    _reviewPromptRequestId.value = request.id
                }
            } catch (_: Exception) {
            }
        }
    }

    fun resetState() {
        _requestState.value = RequestState()
    }

    override fun onCleared() {
        super.onCleared()
        requestsJob?.cancel()
        requestUpdatesJob?.cancel()
        pendingCountJob?.cancel()

        requestRepository.cleanup()
    }
}