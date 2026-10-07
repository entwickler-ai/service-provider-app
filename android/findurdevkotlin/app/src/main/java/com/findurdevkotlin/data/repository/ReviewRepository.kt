package com.findurdevkotlin.data.repository

import com.findurdevkotlin.data.model.Review
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await
import javax.inject.Inject

class ReviewRepository @Inject constructor(
    private val db: FirebaseFirestore
) {

    suspend fun createReview(review: Review): Result<Unit> {
        return try {
            db.collection("reviews").document(review.id).set(review).await()

            if (review.serviceId.isNotEmpty()) {
                updateServiceRating(review.serviceId)
            }

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getProviderRatingStats(providerId: String): Result<Pair<Double, Int>> {
        return try {
            val snapshot = db.collection("reviews")
                .whereEqualTo("providerId", providerId)
                .get()
                .await()

            val reviews = snapshot.toObjects(Review::class.java)

            if (reviews.isNotEmpty()) {
                val avgRating = reviews.map { it.rating }.average()
                Result.success(Pair(avgRating, reviews.size))
            } else {
                Result.success(Pair(0.0, 0))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private suspend fun updateServiceRating(serviceId: String) {
        try {
            val reviewsSnapshot = db.collection("reviews")
                .whereEqualTo("serviceId", serviceId)
                .get()
                .await()

            val reviews = reviewsSnapshot.toObjects(Review::class.java)

            val avgRating = if (reviews.isNotEmpty()) {
                reviews.map { it.rating }.average()
            } else {
                0.0
            }
            val reviewCount = reviews.size

            db.collection("services").document(serviceId).update(
                mapOf(
                    "rating" to avgRating,
                    "reviewCount" to reviewCount
                )
            ).await()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    suspend fun updateProviderServicesRating(providerId: String) {
        try {
            val reviewsSnapshot = db.collection("reviews")
                .whereEqualTo("providerId", providerId)
                .get()
                .await()

            val reviews = reviewsSnapshot.toObjects(Review::class.java)

            if (reviews.isNotEmpty()) {
                val avgRating = reviews.map { it.rating }.average()
                val reviewCount = reviews.size

                val servicesSnapshot = db.collection("services")
                    .whereEqualTo("providerId", providerId)
                    .get()
                    .await()

                val batch = db.batch()
                servicesSnapshot.documents.forEach { serviceDoc ->
                    batch.update(
                        serviceDoc.reference,
                        mapOf(
                            "rating" to avgRating,
                            "reviewCount" to reviewCount
                        )
                    )
                }
                batch.commit().await()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    suspend fun hasUserReviewedRequest(requestId: String, customerId: String): Result<Boolean> {
        return try {
            val snapshot = db.collection("reviews")
                .whereEqualTo("requestId", requestId)
                .whereEqualTo("customerId", customerId)
                .get()
                .await()

            Result.success(!snapshot.isEmpty)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}