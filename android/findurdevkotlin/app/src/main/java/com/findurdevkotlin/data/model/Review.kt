package com.findurdevkotlin.data.model

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

@Parcelize
data class Review(
    val id: String = "",
    val requestId: String = "",
    val serviceId: String = "",
    val providerId: String = "",
    val providerName: String = "",
    val customerId: String = "",
    val customerName: String = "",
    val rating: Int = 0,
    val comment: String = "",
    val createdAt: Long = System.currentTimeMillis()
) : Parcelable

@Parcelize
data class CompletionFile(
    val id: String = "",
    val fileName: String = "",
    val fileUrl: String = "",
    val fileType: String = "",
    val uploadedAt: Long = System.currentTimeMillis(),
    val requestId: String
) : Parcelable

data class ReviewState(
    val isLoading: Boolean = false,
    val isSuccess: Boolean = false,
    val error: String? = null,
    val reviews: List<Review> = emptyList(),
    val averageRating: Double = 0.0,
    val totalReviews: Int = 0
)