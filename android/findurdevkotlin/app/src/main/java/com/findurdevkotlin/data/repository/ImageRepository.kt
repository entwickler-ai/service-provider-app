package com.findurdevkotlin.data.repository

import android.net.Uri
import com.google.firebase.storage.FirebaseStorage
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import java.util.UUID

class ImageRepository @Inject constructor(
    private val storage: FirebaseStorage
) {

    suspend fun uploadProfileImage(userId: String, imageUri: Uri): Result<String> {
        return try {
            val fileName = "profile_${userId}_${UUID.randomUUID()}.jpg"
            val storageRef = storage.reference
                .child("profile_images")
                .child(fileName)

            val uploadTask = storageRef.putFile(imageUri).await()
            val downloadUrl = uploadTask.storage.downloadUrl.await()

            Result.success(downloadUrl.toString())
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deleteProfileImage(imageUrl: String): Result<Unit> {
        return try {
            if (imageUrl.isNotEmpty()) {
                val storageRef = storage.getReferenceFromUrl(imageUrl)
                storageRef.delete().await()
            }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun uploadServiceImage(serviceId: String, imageUri: Uri): Result<String> {
        return try {
            val fileName = "service_${serviceId}_${UUID.randomUUID()}.jpg"
            val storageRef = storage.reference
                .child("service_images")
                .child(fileName)

            val uploadTask = storageRef.putFile(imageUri).await()
            val downloadUrl = uploadTask.storage.downloadUrl.await()

            Result.success(downloadUrl.toString())
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deleteServiceImage(imageUrl: String): Result<Unit> {
        return try {
            if (imageUrl.isNotEmpty()) {
                val storageRef = storage.getReferenceFromUrl(imageUrl)
                storageRef.delete().await()
            }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun uploadMultipleServiceImages(serviceId: String, imageUris: List<Uri>): Result<List<String>> {
        return try {
            val uploadedUrls = mutableListOf<String>()

            for (uri in imageUris) {
                val result = uploadServiceImage(serviceId, uri)
                if (result.isSuccess) {
                    result.getOrNull()?.let { uploadedUrls.add(it) }
                } else {
                    return Result.failure(result.exceptionOrNull() ?: Exception("Upload failed"))
                }
            }

            Result.success(uploadedUrls)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deleteMultipleServiceImages(imageUrls: List<String>): Result<Unit> {
        return try {
            for (url in imageUrls) {
                if (url.isNotEmpty()) {
                    deleteServiceImage(url)
                }
            }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun uploadChatFile(chatId: String, fileUri: Uri, fileName: String): Result<Pair<String, Long>> {
        return try {
            fileName.substringAfterLast(".", "")
            val sanitizedFileName = "chat_${chatId}_${UUID.randomUUID()}_${fileName}"

            val storageRef = storage.reference
                .child("chat_files")
                .child(sanitizedFileName)

            val uploadTask = storageRef.putFile(fileUri).await()
            val downloadUrl = uploadTask.storage.downloadUrl.await()
            val fileSize = uploadTask.metadata?.sizeBytes ?: 0L

            Result.success(Pair(downloadUrl.toString(), fileSize))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun uploadChatImage(chatId: String, imageUri: Uri): Result<Pair<String, Long>> {
        return try {
            val fileName = "chat_img_${chatId}_${UUID.randomUUID()}.jpg"
            val storageRef = storage.reference
                .child("chat_files")
                .child(fileName)

            val uploadTask = storageRef.putFile(imageUri).await()
            val downloadUrl = uploadTask.storage.downloadUrl.await()
            val fileSize = uploadTask.metadata?.sizeBytes ?: 0L

            Result.success(Pair(downloadUrl.toString(), fileSize))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

}