package com.findurdevkotlin.data.repository

import com.findurdevkotlin.data.model.Service
import com.findurdevkotlin.data.model.User
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject

class ServiceRepository @Inject constructor(
    private val db: FirebaseFirestore
) {
    suspend fun createService(service: Service): Result<Unit> {
        return try {
            db.collection("services").document(service.id).set(service).await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getServices(): Result<List<Service>> {
        return try {
            val snapshot = db.collection("services").get().await()
            val services = snapshot.toObjects(Service::class.java)
            Result.success(services)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getServicesByProvider(providerId: String): Result<List<Service>> {
        return try {
            val snapshot = db.collection("services")
                .whereEqualTo("providerId", providerId)
                .get()
                .await()
            val services = snapshot.toObjects(Service::class.java)
            Result.success(services)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun getServiceByIdAsFlow(serviceId: String): Flow<Service?> = callbackFlow {
        val listener = db.collection("services").document(serviceId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }
                trySend(snapshot?.toObject(Service::class.java))
            }
        awaitClose { listener.remove() }
    }
    suspend fun getServiceById(serviceId: String): Result<Service?> {
        return try {
            val snapshot = db.collection("services").document(serviceId).get().await()
            val service = snapshot.toObject(Service::class.java)
            Result.success(service)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun updateService(service: Service): Result<Unit> {
        return try {
            db.collection("services").document(service.id).set(service).await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deleteService(serviceId: String): Result<Unit> {
        return try {
            db.collection("services").document(serviceId).delete().await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getProviderInfo(providerId: String): Result<User?> {
        return try {

            if (providerId.isEmpty()) {
                return Result.success(null)
            }

            val snapshot = db.collection("users").document(providerId).get().await()


            if (!snapshot.exists()) {
                return Result.success(
                    User(
                        uid = providerId,
                        name = "Provider",
                        email = "",
                        role = "provider"
                    )
                )
            }

            val userData = snapshot.data

            if (userData != null) {
                val user = User(
                    uid = userData["uid"] as? String ?: providerId,
                    name = userData["name"] as? String ?: "Provider",
                    email = userData["email"] as? String ?: "",
                    role = userData["role"] as? String ?: "provider",
                    profileImage = userData["profileImage"] as? String ?: "",
                    description = userData["description"] as? String ?: "",
                    location = userData["location"] as? String ?: ""
                )
                Result.success(user)
            } else {
                Result.success(
                    User(
                        uid = providerId,
                        name = "Provider",
                        email = "",
                        role = "provider"
                    )
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
            Result.failure(e)
        }
    }
}