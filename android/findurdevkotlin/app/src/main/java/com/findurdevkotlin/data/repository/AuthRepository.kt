package com.findurdevkotlin.data.repository

import com.findurdevkotlin.data.model.User
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await
import javax.inject.Inject

class AuthRepository @Inject constructor(
    private val auth: FirebaseAuth,
    private val db: FirebaseFirestore
) {
    suspend fun registerUser(email: String, password: String, name: String, role: String): Result<Unit> {
        return try {
            val result = auth.createUserWithEmailAndPassword(email, password).await()
            val uid = result.user?.uid ?: return Result.failure(Exception("UID not found"))

            val user = User(uid = uid, name = name, email = email, role = role)
            db.collection("users").document(uid).set(user).await()

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun loginUser(email: String, password: String): Result<Unit> {
        return try {
            auth.signInWithEmailAndPassword(email, password).await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getUserRole(uid: String): String? {
        return try {
            val snapshot = db.collection("users").document(uid).get().await()
            snapshot.getString("role")
        } catch (_: Exception) {
            null
        }
    }

    suspend fun getUserInfo(uid: String): Result<User?> {
        return try {
            val snapshot = db.collection("users").document(uid).get().await()
            val user = snapshot.toObject(User::class.java)
            Result.success(user)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getCurrentUserInfo(): Result<User?> {
        return try {
            val currentUser = auth.currentUser
            if (currentUser != null) {
                getUserInfo(currentUser.uid)
            } else {
                Result.success(null)
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun updateUserProfile(
        name: String,
        description: String,
        location: String
    ): Result<Unit> {
        return try {
            val currentUser = auth.currentUser
            if (currentUser != null) {
                val userUpdates = mapOf(
                    "name" to name,
                    "description" to description,
                    "location" to location
                )

                db.collection("users")
                    .document(currentUser.uid)
                    .update(userUpdates)
                    .await()

                Result.success(Unit)
            } else {
                Result.failure(Exception("Kein Benutzer angemeldet"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun updateProfileImage(imageUrl: String): Result<Unit> {
        return try {
            val currentUser = auth.currentUser
            if (currentUser != null) {
                db.collection("users")
                    .document(currentUser.uid)
                    .update("profileImage", imageUrl)
                    .await()

                Result.success(Unit)
            } else {
                Result.failure(Exception("Kein Benutzer angemeldet"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    fun logout() {
        auth.signOut()
    }

    fun getCurrentUser() = auth.currentUser
}