package com.findurdevkotlin.ui.service

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.findurdevkotlin.data.model.Service
import com.findurdevkotlin.data.model.User
import com.findurdevkotlin.data.repository.AuthRepository
import com.findurdevkotlin.data.repository.ImageRepository
import com.findurdevkotlin.data.repository.OpenAIService
import com.findurdevkotlin.data.repository.ReviewRepository
import com.findurdevkotlin.data.repository.ServiceRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class ServiceViewModel @Inject constructor(
    private val serviceRepo: ServiceRepository,
    private val authRepo: AuthRepository,
    private val imageRepo: ImageRepository,
    private val reviewRepo: ReviewRepository,
    val openAIService: OpenAIService
) : ViewModel() {

    private val _serviceState = MutableStateFlow(ServiceState())
    val serviceState: StateFlow<ServiceState> = _serviceState

    private val _serviceDetailState = MutableStateFlow(ServiceDetailState())
    val serviceDetailState: StateFlow<ServiceDetailState> = _serviceDetailState

    private val _allServices = MutableStateFlow<List<Service>>(emptyList())

    fun createService(
        title: String,
        description: String,
        price: Double,
        tags: List<String>,
        location: String,
        imageUris: List<Uri> = emptyList()
    ) {
        viewModelScope.launch {
            _serviceState.value = ServiceState(isLoading = true)

            val providerId = authRepo.getCurrentUser()?.uid
            if (providerId == null) {
                _serviceState.value = ServiceState(error = "Benutzer nicht angemeldet")
                return@launch
            }

            val userDoc = serviceRepo.getProviderInfo(providerId).getOrNull()
            val providerName = userDoc?.name ?: "Unbekannter Anbieter"

            try {
                val serviceId = UUID.randomUUID().toString()

                val imageUrls = if (imageUris.isNotEmpty()) {
                    val uploadResult = imageRepo.uploadMultipleServiceImages(serviceId, imageUris)
                    if (uploadResult.isSuccess) {
                        uploadResult.getOrNull() ?: emptyList()
                    } else {
                        _serviceState.value = ServiceState(error = "Fehler beim Hochladen der Bilder")
                        return@launch
                    }
                } else {
                    emptyList()
                }

                val service = Service(
                    id = serviceId,
                    providerId = providerId,
                    providerName = providerName,
                    title = title,
                    description = description,
                    price = price,
                    tags = tags,
                    location = location,
                    portfolioImages = imageUrls,
                    rating = 0.0,
                    reviewCount = 0,
                    createdAt = System.currentTimeMillis(),
                    updatedAt = System.currentTimeMillis()
                )

                val result = serviceRepo.createService(service)
                if (result.isSuccess) {
                    reviewRepo.updateProviderServicesRating(providerId)
                    _serviceState.value = ServiceState(isSuccess = true)
                } else {
                    _serviceState.value = ServiceState(error = result.exceptionOrNull()?.message)
                }
            } catch (e: Exception) {
                _serviceState.value = ServiceState(error = e.message)
            }
        }
    }
    fun updateService(
        serviceId: String,
        title: String,
        description: String,
        price: Double,
        tags: List<String>,
        location: String,
        existingImages: List<String> = emptyList(),
        newImageUris: List<Uri> = emptyList()
    ) {
        viewModelScope.launch {
            _serviceState.value = ServiceState(isLoading = true)

            try {
                val currentService = _serviceDetailState.value.service
                if (currentService == null) {
                    _serviceState.value = ServiceState(error = "Service nicht gefunden")
                    return@launch
                }

                val newImageUrls = if (newImageUris.isNotEmpty()) {
                    val uploadResult = imageRepo.uploadMultipleServiceImages(serviceId, newImageUris)
                    if (uploadResult.isSuccess) {
                        uploadResult.getOrNull() ?: emptyList()
                    } else {
                        _serviceState.value = ServiceState(error = "Fehler beim Hochladen neuer Bilder")
                        return@launch
                    }
                } else {
                    emptyList()
                }

                val allImageUrls = existingImages + newImageUrls

                val updatedService = currentService.copy(
                    title = title,
                    description = description,
                    price = price,
                    tags = tags,
                    location = location,
                    portfolioImages = allImageUrls,
                    updatedAt = System.currentTimeMillis()
                )

                val result = serviceRepo.updateService(updatedService)
                _serviceState.value = if (result.isSuccess) {
                    _serviceDetailState.value = _serviceDetailState.value.copy(service = updatedService)
                    ServiceState(isSuccess = true)
                } else {
                    ServiceState(error = result.exceptionOrNull()?.message)
                }
            } catch (e: Exception) {
                _serviceState.value = ServiceState(error = e.message)
            }
        }
    }

    fun deleteServiceImage(imageUrl: String) {
        viewModelScope.launch {
            try {
                val currentService = _serviceDetailState.value.service
                if (currentService != null) {
                    imageRepo.deleteServiceImage(imageUrl)

                    val updatedImages = currentService.portfolioImages.filter { it != imageUrl }
                    val updatedService = currentService.copy(
                        portfolioImages = updatedImages,
                        updatedAt = System.currentTimeMillis()
                    )

                    serviceRepo.updateService(updatedService)
                    _serviceDetailState.value = _serviceDetailState.value.copy(service = updatedService)
                }
            } catch (e: Exception) {
                _serviceState.value = _serviceState.value.copy(error = e.message)
            }
        }
    }

    fun getServices() {
        viewModelScope.launch {
            _serviceState.value = ServiceState(isLoading = true)
            val result = serviceRepo.getServices()
            if (result.isSuccess) {
                val services = result.getOrNull() ?: emptyList()
                _allServices.value = services
                _serviceState.value = ServiceState(services = services)
            } else {
                _serviceState.value = ServiceState(error = result.exceptionOrNull()?.message)
            }
        }
    }

    fun searchServices(
        query: String = "",
        location: String = "",
        category: String = "",
        minPrice: Double? = null,
        maxPrice: Double? = null,
        sortOrder: String = "newest"
    ) {
        viewModelScope.launch {
            _serviceState.value = ServiceState(isLoading = true)

            var filteredServices = _allServices.value

            if (_allServices.value.isEmpty()) {
                val result = serviceRepo.getServices()
                if (result.isSuccess) {
                    _allServices.value = result.getOrNull() ?: emptyList()
                    filteredServices = _allServices.value
                } else {
                    _serviceState.value = ServiceState(error = result.exceptionOrNull()?.message)
                    return@launch
                }
            }

            filteredServices = filteredServices.filter { service ->
                val matchesQuery = query.isEmpty() ||
                        service.title.contains(query, ignoreCase = true) ||
                        service.description.contains(query, ignoreCase = true) ||
                        service.tags.any { it.contains(query, ignoreCase = true) }

                val matchesLocation = location.isEmpty() ||
                        service.location.contains(location, ignoreCase = true)

                val matchesCategory = category.isEmpty() ||
                        service.tags.any { it.equals(category, ignoreCase = true) } ||
                        service.title.contains(category, ignoreCase = true)

                val matchesMinPrice = minPrice == null || service.price >= minPrice
                val matchesMaxPrice = maxPrice == null || service.price <= maxPrice

                matchesQuery && matchesLocation && matchesCategory &&
                        matchesMinPrice && matchesMaxPrice
            }

            filteredServices = when (sortOrder) {
                "oldest" -> filteredServices.sortedBy { it.createdAt }
                "price_low" -> filteredServices.sortedBy { it.price }
                "price_high" -> filteredServices.sortedByDescending { it.price }
                "rating" -> filteredServices.sortedByDescending { it.rating }
                else -> filteredServices.sortedByDescending { it.createdAt }
            }

            _serviceState.value = ServiceState(services = filteredServices)
        }
    }

    fun getServicesByProvider(providerId: String? = null) {
        viewModelScope.launch {
            _serviceState.value = ServiceState(isLoading = true)

            val actualProviderId = providerId ?: authRepo.getCurrentUser()?.uid
            if (actualProviderId == null) {
                _serviceState.value = ServiceState(error = "Benutzer nicht gefunden")
                return@launch
            }

            val result = serviceRepo.getServicesByProvider(actualProviderId)
            _serviceState.value = if (result.isSuccess) {
                ServiceState(services = result.getOrNull() ?: emptyList())
            } else {
                ServiceState(error = result.exceptionOrNull()?.message)
            }
        }
    }

    fun resetState() {
        _serviceState.value = ServiceState()
    }

    fun getServiceById(serviceId: String) {
        viewModelScope.launch {
            _serviceDetailState.value = ServiceDetailState(isLoading = true)

            try {
                serviceRepo.getServiceByIdAsFlow(serviceId).collect { service ->
                    if (service == null) {
                        _serviceDetailState.value = ServiceDetailState(error = "Service nicht gefunden")
                        return@collect
                    }

                    val providerResult = serviceRepo.getProviderInfo(service.providerId)
                    val provider = providerResult.getOrNull()

                    _serviceDetailState.value = ServiceDetailState(
                        service = service,
                        provider = provider,
                        isOwner = authRepo.getCurrentUser()?.uid == service.providerId
                    )
                }
            } catch (e: Exception) {
                _serviceDetailState.value = ServiceDetailState(error = e.message)
            }
        }
    }

    fun deleteService(serviceId: String) {
        viewModelScope.launch {
            _serviceDetailState.value = _serviceDetailState.value.copy(isLoading = true)

            try {
                val currentService = _serviceDetailState.value.service

                if (currentService != null && currentService.portfolioImages.isNotEmpty()) {
                    imageRepo.deleteMultipleServiceImages(currentService.portfolioImages)
                }

                val result = serviceRepo.deleteService(serviceId)
                _serviceDetailState.value = if (result.isSuccess) {
                    _serviceDetailState.value.copy(isLoading = false, isDeleted = true)
                } else {
                    _serviceDetailState.value.copy(
                        isLoading = false,
                        error = result.exceptionOrNull()?.message
                    )
                }
            } catch (e: Exception) {
                _serviceDetailState.value = _serviceDetailState.value.copy(
                    isLoading = false,
                    error = e.message
                )
            }
        }
    }
}

data class ServiceState(
    val isLoading: Boolean = false,
    val isSuccess: Boolean = false,
    val error: String? = null,
    val services: List<Service> = emptyList(),
    val isUploadingImages: Boolean = false
)

data class ServiceDetailState(
    val isLoading: Boolean = false,
    val service: Service? = null,
    val provider: User? = null,
    val isOwner: Boolean = false,
    val isDeleted: Boolean = false,
    val error: String? = null
)