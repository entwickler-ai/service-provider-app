package com.findurdevkotlin.data.model

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

@Parcelize
data class Request(
    val id: String = "",
    val serviceId: String = "",
    val serviceTitle: String = "",
    val providerId: String = "",
    val providerName: String = "",
    val customerId: String = "",
    val customerName: String = "",
    val title: String = "",
    val description: String = "",
    val budget: Double = 0.0,
    val timeline: String = "",
    val status: RequestStatus = RequestStatus.PENDING,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val providerResponse: String = "",
    val completionNotes: String = "",
    val requirements: List<String> = emptyList(),
    val attachments: List<String> = emptyList(),
    val chatId: String = ""
) : Parcelable

enum class RequestStatus {
    PENDING, ACCEPTED, REJECTED, IN_PROGRESS, COMPLETED, CANCELLED;

    fun getDisplayName(): String {
        return when (this) {
            PENDING -> "Ausstehend"
            ACCEPTED -> "Angenommen"
            REJECTED -> "Abgelehnt"
            IN_PROGRESS -> "In Bearbeitung"
            COMPLETED -> "Abgeschlossen"
            CANCELLED -> "Abgebrochen"
        }
    }
}

@Parcelize
data class RequestStatusHistory(
    val id: String = "",
    val requestId: String = "",
    val status: RequestStatus = RequestStatus.PENDING,
    val timestamp: Long = System.currentTimeMillis(),
    val notes: String = "",
    val updatedBy: String = ""
) : Parcelable

data class RequestState(
    val isLoading: Boolean = false,
    val isSuccess: Boolean = false,
    val error: String? = null,
    val requests: List<Request> = emptyList()
)

data class RequestDetailState(
    val isLoading: Boolean = false,
    val request: Request? = null,
    val statusHistory: List<RequestStatusHistory> = emptyList(),
    val error: String? = null,
    val isUpdating: Boolean = false
)

fun RequestStatus.getNextPossibleStatuses(isProvider: Boolean): List<RequestStatus> = when (this) {
    RequestStatus.PENDING -> if (isProvider) {
        listOf(RequestStatus.ACCEPTED, RequestStatus.REJECTED)
    } else {
        listOf(RequestStatus.CANCELLED)
    }
    RequestStatus.ACCEPTED -> if (isProvider) {
        listOf(RequestStatus.IN_PROGRESS, RequestStatus.REJECTED)
    } else {
        listOf(RequestStatus.CANCELLED)
    }
    RequestStatus.IN_PROGRESS -> if (isProvider) {
        listOf(RequestStatus.COMPLETED)
    } else {
        listOf(RequestStatus.CANCELLED)
    }
    else -> emptyList()
}

fun RequestStatus.canBeUpdatedBy(isProvider: Boolean): Boolean = when (this) {
    RequestStatus.PENDING -> true
    RequestStatus.ACCEPTED -> true
    RequestStatus.IN_PROGRESS -> isProvider
    else -> false
}