package com.findurdevkotlin.data.repository

import com.findurdevkotlin.data.model.Request
import com.findurdevkotlin.data.model.RequestStatus
import com.findurdevkotlin.data.model.RequestStatusHistory
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.Query
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import java.util.UUID

class RequestRepository @Inject constructor(
    private val db: FirebaseFirestore
) {

    private val activeListeners = mutableMapOf<String, ListenerRegistration>()

    suspend fun createRequest(request: Request): Result<String> {
        return try {
            val requestId = UUID.randomUUID().toString()
            val requestWithId = request.copy(id = requestId)

            db.collection("requests").document(requestId).set(requestWithId).await()

            val initialHistory = RequestStatusHistory(
                id = UUID.randomUUID().toString(),
                requestId = requestId,
                status = RequestStatus.PENDING,
                timestamp = System.currentTimeMillis(),
                notes = "Anfrage erstellt",
                updatedBy = request.customerId
            )

            db.collection("request_history")
                .document(initialHistory.id)
                .set(initialHistory)
                .await()

            Result.success(requestId)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun getCustomerRequests(customerId: String): Flow<List<Request>> = callbackFlow {
        val listenerId = "customer_$customerId"

        activeListeners[listenerId]?.remove()

        val listener = db.collection("requests")
            .whereEqualTo("customerId", customerId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }

                val requests = snapshot?.toObjects(Request::class.java) ?: emptyList()

                val uniqueRequests = requests
                    .distinctBy { it.id }
                    .filter { it.id.isNotEmpty() }
                    .sortedByDescending { it.createdAt }

                trySend(uniqueRequests)
            }

        activeListeners[listenerId] = listener

        awaitClose {
            activeListeners.remove(listenerId)
            listener.remove()
        }
    }

    fun getProviderRequests(providerId: String): Flow<List<Request>> = callbackFlow {
        val listenerId = "provider_$providerId"

        activeListeners[listenerId]?.remove()

        val listener = db.collection("requests")
            .whereEqualTo("providerId", providerId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }

                val requests = snapshot?.toObjects(Request::class.java) ?: emptyList()

                val uniqueRequests = requests
                    .distinctBy { it.id }
                    .filter { it.id.isNotEmpty() }
                    .sortedByDescending { it.createdAt }

                trySend(uniqueRequests)
            }

        activeListeners[listenerId] = listener

        awaitClose {
            activeListeners.remove(listenerId)
            listener.remove()
        }
    }

    suspend fun getRequestById(requestId: String): Result<Request?> {
        return try {
            val snapshot = db.collection("requests").document(requestId).get().await()
            val request = snapshot.toObject(Request::class.java)
            Result.success(request)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun updateRequestStatus(
        requestId: String,
        newStatus: RequestStatus,
        response: String = "",
        updatedBy: String
    ): Result<Unit> {
        return try {
            val batch = db.batch()

            val requestRef = db.collection("requests").document(requestId)
            val currentRequest = requestRef.get().await().toObject(Request::class.java)

            if (currentRequest != null) {
                val updatedRequest = currentRequest.copy(
                    status = newStatus,
                    updatedAt = System.currentTimeMillis(),
                    providerResponse = response.ifEmpty { currentRequest.providerResponse }
                )
                batch.set(requestRef, updatedRequest)

                val historyEntry = RequestStatusHistory(
                    id = UUID.randomUUID().toString(),
                    requestId = requestId,
                    status = newStatus,
                    timestamp = System.currentTimeMillis(),
                    notes = response,
                    updatedBy = updatedBy
                )

                val historyRef = db.collection("request_history").document(historyEntry.id)
                batch.set(historyRef, historyEntry)

                batch.commit().await()
                Result.success(Unit)
            } else {
                Result.failure(Exception("Request not found"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getRequestHistory(requestId: String): Result<List<RequestStatusHistory>> {
        return try {
            val snapshot = db.collection("request_history")
                .whereEqualTo("requestId", requestId)
                .orderBy("timestamp", Query.Direction.ASCENDING)
                .get()
                .await()

            val history = snapshot.toObjects(RequestStatusHistory::class.java)
                .distinctBy { it.id }
                .filter { it.id.isNotEmpty() }

            Result.success(history)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getPendingRequestsCount(providerId: String): Result<Int> {
        return try {
            val snapshot = db.collection("requests")
                .whereEqualTo("providerId", providerId)
                .whereEqualTo("status", RequestStatus.PENDING.name)
                .get()
                .await()

            val uniqueRequests = snapshot.toObjects(Request::class.java)
                .distinctBy { it.id }
                .filter { it.id.isNotEmpty() }

            Result.success(uniqueRequests.size)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deleteRequest(requestId: String, userId: String): Result<Unit> {
        return try {
            val requestSnapshot = db.collection("requests").document(requestId).get().await()
            val request = requestSnapshot.toObject(Request::class.java)

            if (request == null) {
                return Result.failure(Exception("Request not found"))
            }

            if (request.customerId != userId) {
                return Result.failure(Exception("Not authorized to delete this request"))
            }

            if (request.status != RequestStatus.PENDING) {
                return Result.failure(Exception("Can only delete pending requests"))
            }

            val batch = db.batch()
            batch.delete(db.collection("requests").document(requestId))

            val historySnapshot = db.collection("request_history")
                .whereEqualTo("requestId", requestId)
                .get()
                .await()

            historySnapshot.documents.forEach { doc ->
                batch.delete(doc.reference)
            }

            batch.commit().await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun getRequestsByStatus(
        userId: String,
        isProvider: Boolean,
        status: RequestStatus
    ): Flow<List<Request>> = callbackFlow {
        val field = if (isProvider) "providerId" else "customerId"
        val listenerId = "${if (isProvider) "provider" else "customer"}_${userId}_${status.name}"

        activeListeners[listenerId]?.remove()

        val listener = db.collection("requests")
            .whereEqualTo(field, userId)
            .whereEqualTo("status", status.name)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }

                val requests = snapshot?.toObjects(Request::class.java) ?: emptyList()

                val uniqueRequests = requests
                    .distinctBy { it.id }
                    .filter { it.id.isNotEmpty() }
                    .sortedByDescending { it.updatedAt }

                trySend(uniqueRequests)
            }

        activeListeners[listenerId] = listener

        awaitClose {
            activeListeners.remove(listenerId)
            listener.remove()
        }
    }

    suspend fun getActiveRequestsCount(providerId: String): Result<Int> {
        return try {
            val snapshot = db.collection("requests")
                .whereEqualTo("providerId", providerId)
                .get()
                .await()

            val activeRequests = snapshot.toObjects(Request::class.java)
                .filter { request ->
                    request.status == RequestStatus.ACCEPTED ||
                            request.status == RequestStatus.IN_PROGRESS
                }
                .distinctBy { it.id }
                .filter { it.id.isNotEmpty() }

            Result.success(activeRequests.size)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun cleanup() {
        activeListeners.values.forEach { it.remove() }
        activeListeners.clear()
    }
}