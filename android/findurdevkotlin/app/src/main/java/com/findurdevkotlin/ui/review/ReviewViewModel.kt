package com.findurdevkotlin.ui.review

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.findurdevkotlin.data.model.Review
import com.findurdevkotlin.data.model.ReviewState
import com.findurdevkotlin.data.repository.AuthRepository
import com.findurdevkotlin.data.repository.ReviewRepository
import com.findurdevkotlin.data.repository.RequestRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import java.util.UUID

@HiltViewModel
class ReviewViewModel @Inject constructor(
    private val reviewRepository: ReviewRepository,
    private val requestRepository: RequestRepository,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _reviewState = MutableStateFlow(ReviewState())

    private val currentUserId = authRepository.getCurrentUser()?.uid ?: ""

    fun submitReview(requestId: String, rating: Int) {
        viewModelScope.launch {
            _reviewState.value = _reviewState.value.copy(isLoading = true)

            try {
                val requestResult = requestRepository.getRequestById(requestId)
                val request = requestResult.getOrNull()

                if (request != null) {
                    val userResult = authRepository.getCurrentUserInfo()
                    val user = userResult.getOrNull()

                    if (user != null) {
                        val review = Review(
                            id = UUID.randomUUID().toString(),
                            requestId = requestId,
                            serviceId = request.serviceId,
                            providerId = request.providerId,
                            providerName = request.providerName,
                            customerId = currentUserId,
                            customerName = user.name,
                            rating = rating,
                            comment = ""
                        )

                        val result = reviewRepository.createReview(review)

                        if (result.isSuccess) {
                            _reviewState.value = _reviewState.value.copy(
                                isLoading = false,
                                isSuccess = true
                            )
                        } else {
                            _reviewState.value = _reviewState.value.copy(
                                isLoading = false,
                                error = "Fehler beim Speichern der Bewertung"
                            )
                        }
                    }
                }
            } catch (e: Exception) {
                _reviewState.value = _reviewState.value.copy(
                    isLoading = false,
                    error = e.message
                )
            }
        }
    }
}