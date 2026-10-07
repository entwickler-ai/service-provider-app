package com.findurdevkotlin.ui.profile

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.findurdevkotlin.data.model.User
import com.findurdevkotlin.data.repository.AuthRepository
import com.findurdevkotlin.data.repository.ImageRepository
import com.findurdevkotlin.data.repository.ServiceRepository
import com.findurdevkotlin.data.repository.RequestRepository
import com.findurdevkotlin.data.repository.ReviewRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val imageRepository: ImageRepository,
    private val serviceRepository: ServiceRepository,
    private val requestRepository: RequestRepository,
    private val reviewRepository: ReviewRepository
) : ViewModel() {

    private val _profileState = MutableStateFlow(ProfileState())
    val profileState: StateFlow<ProfileState> = _profileState

    private val _statsState = MutableStateFlow(ProviderStats())
    val statsState: StateFlow<ProviderStats> = _statsState

    val currentUserId = authRepository.getCurrentUser()?.uid ?: ""

    fun loadUserProfile() {
        viewModelScope.launch {
            _profileState.value = ProfileState(isLoading = true)

            try {
                val result = authRepository.getCurrentUserInfo()
                if (result.isSuccess) {
                    val user = result.getOrNull()
                    _profileState.value = ProfileState(user = user)

                    if (user?.role == "provider") {
                        loadProviderStats()
                    }
                } else {
                    _profileState.value = ProfileState(
                        error = result.exceptionOrNull()?.message ?: "Fehler beim Laden des Profils"
                    )
                }
            } catch (e: Exception) {
                _profileState.value = ProfileState(error = e.message)
            }
        }
    }

    private fun loadProviderStats() {
        viewModelScope.launch {
            _statsState.value = ProviderStats(isLoading = true)

            try {
                val servicesResult = serviceRepository.getServicesByProvider(currentUserId)
                val servicesCount = if (servicesResult.isSuccess) {
                    servicesResult.getOrNull()?.size ?: 0
                } else {
                    0
                }

                val ratingStatsResult = reviewRepository.getProviderRatingStats(currentUserId)
                val (avgRating, totalReviews) = if (ratingStatsResult.isSuccess) {
                    ratingStatsResult.getOrNull() ?: Pair(0.0, 0)
                } else {
                    Pair(0.0, 0)
                }

                val activeRequestsResult = requestRepository.getActiveRequestsCount(currentUserId)
                val activeRequestsCount = if (activeRequestsResult.isSuccess) {
                    activeRequestsResult.getOrNull() ?: 0
                } else {
                    0
                }

                _statsState.value = ProviderStats(
                    servicesCount = servicesCount,
                    averageRating = avgRating,
                    totalReviews = totalReviews,
                    activeRequestsCount = activeRequestsCount,
                    isLoading = false
                )

            } catch (e: Exception) {
                _statsState.value = ProviderStats(
                    isLoading = false,
                    error = e.message
                )
            }
        }
    }

    fun updateUserProfile(
        name: String,
        description: String,
        location: String
    ) {
        viewModelScope.launch {
            _profileState.value = _profileState.value.copy(isUpdating = true)

            try {
                val result = authRepository.updateUserProfile(
                    name = name,
                    description = description,
                    location = location
                )

                if (result.isSuccess) {
                    val updatedUser = _profileState.value.user?.copy(
                        name = name,
                        description = description,
                        location = location
                    )
                    _profileState.value = _profileState.value.copy(
                        isUpdating = false,
                        isSuccess = true,
                        user = updatedUser
                    )
                } else {
                    _profileState.value = _profileState.value.copy(
                        isUpdating = false,
                        error = result.exceptionOrNull()?.message ?: "Fehler beim Speichern"
                    )
                }
            } catch (e: Exception) {
                _profileState.value = _profileState.value.copy(
                    isUpdating = false,
                    error = e.message
                )
            }
        }
    }

    fun uploadProfileImage(imageUri: Uri) {
        viewModelScope.launch {
            _profileState.value = _profileState.value.copy(isUploadingImage = true)

            try {
                val currentUser = _profileState.value.user
                if (currentUser != null) {
                    if (currentUser.profileImage.isNotEmpty()) {
                        imageRepository.deleteProfileImage(currentUser.profileImage)
                    }

                    val uploadResult = imageRepository.uploadProfileImage(currentUserId, imageUri)

                    if (uploadResult.isSuccess) {
                        val imageUrl = uploadResult.getOrNull() ?: ""

                        val updateResult = authRepository.updateProfileImage(imageUrl)

                        if (updateResult.isSuccess) {
                            val updatedUser = currentUser.copy(profileImage = imageUrl)
                            _profileState.value = _profileState.value.copy(
                                isUploadingImage = false,
                                user = updatedUser
                            )
                        } else {
                            _profileState.value = _profileState.value.copy(
                                isUploadingImage = false,
                                error = "Fehler beim Speichern des Profilbilds"
                            )
                        }
                    } else {
                        _profileState.value = _profileState.value.copy(
                            isUploadingImage = false,
                            error = "Fehler beim Hochladen des Bilds"
                        )
                    }
                } else {
                    _profileState.value = _profileState.value.copy(
                        isUploadingImage = false,
                        error = "Benutzerdaten nicht gefunden"
                    )
                }
            } catch (e: Exception) {
                _profileState.value = _profileState.value.copy(
                    isUploadingImage = false,
                    error = e.message
                )
            }
        }
    }

    fun deleteProfileImage() {
        viewModelScope.launch {
            _profileState.value = _profileState.value.copy(isUploadingImage = true)

            try {
                val currentUser = _profileState.value.user
                if (currentUser != null && currentUser.profileImage.isNotEmpty()) {
                    imageRepository.deleteProfileImage(currentUser.profileImage)

                    val updateResult = authRepository.updateProfileImage("")

                    if (updateResult.isSuccess) {
                        val updatedUser = currentUser.copy(profileImage = "")
                        _profileState.value = _profileState.value.copy(
                            isUploadingImage = false,
                            user = updatedUser
                        )
                    } else {
                        _profileState.value = _profileState.value.copy(
                            isUploadingImage = false,
                            error = "Fehler beim Löschen des Profilbilds"
                        )
                    }
                }
            } catch (e: Exception) {
                _profileState.value = _profileState.value.copy(
                    isUploadingImage = false,
                    error = e.message
                )
            }
        }
    }

    fun resetState() {
        _profileState.value = ProfileState()
        _statsState.value = ProviderStats()
    }

}

data class ProfileState(
    val isLoading: Boolean = false,
    val isUpdating: Boolean = false,
    val isUploadingImage: Boolean = false,
    val isSuccess: Boolean = false,
    val user: User? = null,
    val error: String? = null
)

data class ProviderStats(
    val isLoading: Boolean = false,
    val servicesCount: Int = 0,
    val averageRating: Double = 0.0,
    val totalReviews: Int = 0,
    val activeRequestsCount: Int = 0,
    val error: String? = null
)