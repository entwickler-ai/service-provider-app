package com.findurdevkotlin.data.model

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

@Parcelize
data class Service(
    val id: String = "",
    val providerId: String = "",
    val providerName: String = "",
    val title: String = "",
    val description: String = "",
    val price: Double = 0.0,
    val tags: List<String> = emptyList(),
    val portfolioImages: List<String> = emptyList(),
    val location: String = "",
    val rating: Double? = null,
    val reviewCount: Int = 0,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
) : Parcelable