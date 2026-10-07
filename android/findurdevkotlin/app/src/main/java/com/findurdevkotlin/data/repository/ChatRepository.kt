package com.findurdevkotlin.data.repository

import android.net.Uri
import com.findurdevkotlin.data.model.*
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import java.util.UUID

class ChatRepository @Inject constructor(
    val db: FirebaseFirestore
) {

    suspend fun createOrGetChat(
        currentUserId: String,
        otherUserId: String,
        serviceId: String? = null,
        serviceTitle: String? = null
    ): Result<Chat> {
        return try {
            val existingChatQuery = db.collection("chats")
                .whereArrayContains("participants", currentUserId)
                .get()
                .await()

            var existingChat: Chat? = null
            for (document in existingChatQuery.documents) {
                val chat = document.toObject(Chat::class.java)
                if (chat != null && chat.participants.contains(otherUserId)) {
                    existingChat = chat
                    break
                }
            }

            if (existingChat != null) {
                val refreshedChat = refreshExistingChatNames(existingChat)
                Result.success(refreshedChat)
            } else {
                val currentUserResult = getUserInfo(currentUserId)
                val currentUser = currentUserResult.getOrNull()
                val isCurrentUserProvider = currentUser?.role == "provider"

                val otherUserName = if (serviceId != null) {
                    val serviceRepo = ServiceRepository(db)
                    val serviceResult = serviceRepo.getServiceById(serviceId)
                    if (isCurrentUserProvider) {
                        getUserInfo(otherUserId).getOrNull()?.name ?: "Benutzer"
                    } else {
                        if (serviceResult.isSuccess) {
                            val service = serviceResult.getOrNull()
                            service?.providerName ?: getUserInfo(otherUserId).getOrNull()?.name ?: "Benutzer"
                        } else {
                            getUserInfo(otherUserId).getOrNull()?.name ?: "Benutzer"
                        }
                    }
                } else {
                    getUserInfo(otherUserId).getOrNull()?.name ?: "Benutzer"
                }

                val chatId = UUID.randomUUID().toString()
                val newChat = Chat(
                    id = chatId,
                    participants = listOf(currentUserId, otherUserId),
                    participantNames = mapOf(
                        currentUserId to (currentUser?.name ?: "Benutzer"),
                        otherUserId to otherUserName
                    ),
                    serviceId = serviceId ?: "",
                    serviceTitle = serviceTitle ?: "",
                    unreadCount = mapOf(
                        currentUserId to 0,
                        otherUserId to 0
                    ),
                    hiddenForUsers = emptyList()
                )

                db.collection("chats").document(chatId).set(newChat).await()
                Result.success(newChat)
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun unhideAndSetTemporaryEmpty(chatId: String, userId: String): Result<Unit> {
        return try {
            val chatRef = db.collection("chats").document(chatId)
            val chatSnapshot = chatRef.get().await()
            val chat = chatSnapshot.toObject(Chat::class.java)

            if (chat != null) {
                val updatedHiddenUsers = chat.hiddenForUsers.toMutableList()
                val updatedTemporaryEmpty = chat.temporaryEmptyForUsers.toMutableList()

                updatedHiddenUsers.remove(userId)

                if (!updatedTemporaryEmpty.contains(userId)) {
                    updatedTemporaryEmpty.add(userId)
                }

                val updatedChat = chat.copy(
                    hiddenForUsers = updatedHiddenUsers,
                    temporaryEmptyForUsers = updatedTemporaryEmpty
                )
                chatRef.set(updatedChat).await()
            }

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    private suspend fun refreshExistingChatNames(chat: Chat): Chat {
        return try {
            val updatedParticipantNames = mutableMapOf<String, String>()

            for (participantId in chat.participants) {
                val currentName = chat.participantNames[participantId]
                if (currentName == null || currentName == "Benutzer" || currentName == "Unknown User" || currentName.startsWith("User ") || currentName.contains("Unknown")) {
                    val userResult = getUserInfo(participantId)
                    val user = userResult.getOrNull()
                    updatedParticipantNames[participantId] = user?.name ?: "Benutzer"
                } else {
                    updatedParticipantNames[participantId] = currentName
                }
            }

            val updatedChat = chat.copy(participantNames = updatedParticipantNames)
            db.collection("chats").document(chat.id).set(updatedChat).await()
            updatedChat
        } catch (_: Exception) {
            chat
        }
    }

    private suspend fun getUserInfo(userId: String): Result<User?> {
        return try {
            val snapshot = db.collection("users").document(userId).get().await()

            if (!snapshot.exists()) {
                val serviceRepo = ServiceRepository(db)
                val providerResult = serviceRepo.getProviderInfo(userId)
                if (providerResult.isSuccess) {
                    val provider = providerResult.getOrNull()
                    if (provider != null) {
                        return Result.success(User(
                            uid = userId,
                            name = provider.name,
                            role = "provider",
                            profileImage = provider.profileImage,
                            description = provider.description,
                            location = provider.location
                        ))
                    }
                }
                return Result.success(User(uid = userId, name = "Benutzer", role = ""))
            }

            val user = snapshot.toObject(User::class.java)
            if (user != null) {
                Result.success(user)
            } else {
                val userData = snapshot.data
                if (userData != null) {
                    val manualUser = User(
                        uid = userData["uid"] as? String ?: userId,
                        name = userData["name"] as? String ?: "Benutzer",
                        email = userData["email"] as? String ?: "",
                        role = userData["role"] as? String ?: "",
                        profileImage = userData["profileImage"] as? String ?: "",
                        description = userData["description"] as? String ?: "",
                        location = userData["location"] as? String ?: ""
                    )
                    Result.success(manualUser)
                } else {
                    val serviceRepo = ServiceRepository(db)
                    val providerResult = serviceRepo.getProviderInfo(userId)
                    if (providerResult.isSuccess) {
                        val provider = providerResult.getOrNull()
                        if (provider != null) {
                            return Result.success(User(
                                uid = userId,
                                name = provider.name,
                                role = "provider",
                                profileImage = provider.profileImage,
                                description = provider.description,
                                location = provider.location
                            ))
                        }
                    }
                    Result.success(User(uid = userId, name = "Benutzer", role = ""))
                }
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun getUserChats(userId: String): Flow<List<Chat>> = callbackFlow {
        val listener = db.collection("chats")
            .whereArrayContains("participants", userId)
            .orderBy("lastMessageTimestamp", Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }

                val chats = snapshot?.toObjects(Chat::class.java)?.filter { chat ->
                    !chat.hiddenForUsers.contains(userId) &&
                            !chat.pendingUnhideForUsers.contains(userId)
                } ?: emptyList()

                trySend(chats)
            }

        awaitClose { listener.remove() }
    }

    suspend fun sendMessage(
        chatId: String,
        senderId: String,
        senderName: String,
        content: String
    ): Result<Unit> {
        return try {
            val messageId = UUID.randomUUID().toString()
            val message = Message(
                id = messageId,
                chatId = chatId,
                senderId = senderId,
                senderName = senderName,
                content = content,
                timestamp = System.currentTimeMillis()
            )

            db.collection("messages").document(messageId).set(message).await()

            val chatRef = db.collection("chats").document(chatId)
            val chatSnapshot = chatRef.get().await()
            val chat = chatSnapshot.toObject(Chat::class.java)

            if (chat != null) {
                val updatedUnreadCount = chat.unreadCount.toMutableMap()
                val updatedTemporaryEmpty = chat.temporaryEmptyForUsers.toMutableList()
                val updatedHiddenUsers = chat.hiddenForUsers.toMutableList()
                val updatedPendingUnhide = chat.pendingUnhideForUsers.toMutableList()
                val updatedConnectionStatus = chat.connectionStatus.toMutableMap()

                updatedTemporaryEmpty.remove(senderId)
                updatedHiddenUsers.remove(senderId)
                updatedPendingUnhide.remove(senderId)

                updatedConnectionStatus[senderId] = ChatConnectionStatus.CONNECTED

                chat.participants.forEach { participantId ->
                    if (participantId != senderId) {
                        updatedUnreadCount[participantId] = (updatedUnreadCount[participantId] ?: 0) + 1
                    }
                }

                val updatedChat = chat.copy(
                    lastMessage = content,
                    lastMessageTimestamp = System.currentTimeMillis(),
                    lastMessageSenderId = senderId,
                    unreadCount = updatedUnreadCount,
                    temporaryEmptyForUsers = updatedTemporaryEmpty,
                    hiddenForUsers = updatedHiddenUsers,
                    pendingUnhideForUsers = updatedPendingUnhide,
                    connectionStatus = updatedConnectionStatus
                )

                chatRef.set(updatedChat).await()
            }

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun getChatMessages(chatId: String): Flow<List<Message>> = callbackFlow {
        val listener = db.collection("messages")
            .whereEqualTo("chatId", chatId)
            .orderBy("timestamp", Query.Direction.ASCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }

                val messages = snapshot?.toObjects(Message::class.java) ?: emptyList()
                trySend(messages)
            }

        awaitClose { listener.remove() }
    }

    suspend fun getChatById(chatId: String): Result<Chat?> {
        return try {
            val snapshot = db.collection("chats").document(chatId).get().await()
            val chat = snapshot.toObject(Chat::class.java)
            Result.success(chat)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun prepareHiddenChatForWriting(chatId: String, userId: String): Result<Unit> {
        return try {
            val chatRef = db.collection("chats").document(chatId)
            val chatSnapshot = chatRef.get().await()
            val chat = chatSnapshot.toObject(Chat::class.java)

            if (chat != null) {
                val updatedPendingUnhide = chat.pendingUnhideForUsers.toMutableList()
                val updatedTemporaryEmpty = chat.temporaryEmptyForUsers.toMutableList()
                val updatedConnectionStatus = chat.connectionStatus.toMutableMap()

                if (!updatedPendingUnhide.contains(userId)) {
                    updatedPendingUnhide.add(userId)
                }

                if (!updatedTemporaryEmpty.contains(userId)) {
                    updatedTemporaryEmpty.add(userId)
                }

                updatedConnectionStatus[userId] = ChatConnectionStatus.READY

                val updatedChat = chat.copy(
                    pendingUnhideForUsers = updatedPendingUnhide,
                    temporaryEmptyForUsers = updatedTemporaryEmpty,
                    connectionStatus = updatedConnectionStatus
                )
                chatRef.set(updatedChat).await()
            }

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    suspend fun migrateAllChatsNames(): Result<Unit> {
        return try {
            val chatsSnapshot = db.collection("chats").get().await()
            var updatedCount = 0

            for (document in chatsSnapshot.documents) {
                val chat = document.toObject(Chat::class.java)
                if (chat != null) {
                    val updatedParticipantNames = mutableMapOf<String, String>()
                    var hasChanges = false

                    for (participantId in chat.participants) {
                        val currentName = chat.participantNames[participantId]

                        if (currentName == null ||
                            currentName == "Unknown User" ||
                            currentName.startsWith("User ") ||
                            currentName.contains("Unknown")) {

                            val userResult = getUserInfo(participantId)
                            val user = userResult.getOrNull()
                            user?.name ?: "Benutzer"

                            updatedParticipantNames[participantId] = user?.name ?: "Benutzer"
                            hasChanges = true
                        } else {
                            updatedParticipantNames[participantId] = currentName
                        }
                    }

                    val hiddenForUsers = if (!document.data?.containsKey("hiddenForUsers")!!) {
                        hasChanges = true
                        emptyList()
                    } else {
                        chat.hiddenForUsers
                    }

                    if (hasChanges) {
                        val updatedChat = chat.copy(
                            participantNames = updatedParticipantNames,
                            hiddenForUsers = hiddenForUsers
                        )

                        db.collection("chats").document(chat.id).set(updatedChat).await()
                        updatedCount++
                    }
                }
            }

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun deleteChat(chatId: String, userId: String): Result<Unit> {
        return try {
            val chatRef = db.collection("chats").document(chatId)
            val chatSnapshot = chatRef.get().await()
            val chat = chatSnapshot.toObject(Chat::class.java)

            if (chat != null) {
                val hiddenForUsers = chat.hiddenForUsers.toMutableList()
                if (!hiddenForUsers.contains(userId)) {
                    hiddenForUsers.add(userId)

                    val updatedChat = chat.copy(hiddenForUsers = hiddenForUsers)
                    chatRef.set(updatedChat).await()
                }
            }

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun markMessagesAsRead(chatId: String, userId: String): Result<Unit> {
        return try {
            val chatRef = db.collection("chats").document(chatId)
            val chatSnapshot = chatRef.get().await()
            val chat = chatSnapshot.toObject(Chat::class.java)

            if (chat != null) {
                val currentUnreadCount = chat.unreadCount[userId] ?: 0

                if (currentUnreadCount > 0) {
                    val updatedUnreadCount = chat.unreadCount.toMutableMap()
                    updatedUnreadCount[userId] = 0

                    val updatedChat = chat.copy(unreadCount = updatedUnreadCount)
                    chatRef.set(updatedChat).await()
                }
            }

            val unreadMessages = db.collection("messages")
                .whereEqualTo("chatId", chatId)
                .whereNotEqualTo("senderId", userId)
                .whereEqualTo("isRead", false)
                .get()
                .await()

            if (unreadMessages.documents.isNotEmpty()) {
                val batch = db.batch()
                unreadMessages.documents.forEach { document ->
                    batch.update(document.reference, "isRead", true)
                }
                batch.commit().await()
            }

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getTotalUnreadCount(userId: String): Result<Int> {
        return try {
            val chatsSnapshot = db.collection("chats")
                .whereArrayContains("participants", userId)
                .get()
                .await()

            var totalUnread = 0
            chatsSnapshot.documents.forEach { document ->
                val chat = document.toObject(Chat::class.java)
                if (chat != null && !chat.hiddenForUsers.contains(userId)) {
                    totalUnread += chat.unreadCount[userId] ?: 0
                }
            }

            Result.success(totalUnread)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun refreshChatParticipantNames(chatId: String, currentUserId: String): Result<Unit> {
        return try {
            val chatRef = db.collection("chats").document(chatId)
            val chatSnapshot = chatRef.get().await()
            val chat = chatSnapshot.toObject(Chat::class.java)

            if (chat != null) {
                val updatedParticipantNames = mutableMapOf<String, String>()
                val serviceRepo = ServiceRepository(db)

                val currentUserResult = getUserInfo(currentUserId)
                val currentUser = currentUserResult.getOrNull()
                val isCurrentUserProvider = currentUser?.role == "provider"

                for (participantId in chat.participants) {
                    val userResult = getUserInfo(participantId)
                    val user = userResult.getOrNull()

                    val assignedName = if (chat.serviceId.isNotEmpty() && participantId != currentUserId) {
                        if (isCurrentUserProvider) {

                            user?.name ?: run {
                                println("Warning: No name found for participant $participantId, falling back to 'Benutzer'")
                                "Benutzer"
                            }
                        } else {

                            val serviceResult = serviceRepo.getServiceById(chat.serviceId)
                            if (serviceResult.isSuccess) {
                                val service = serviceResult.getOrNull()
                                service?.providerName ?: run {
                                    println("Warning: No providerName found for service ${chat.serviceId}, falling back to user name or 'Benutzer'")
                                    user?.name ?: "Benutzer"
                                }
                            } else {
                                user?.name ?: "Benutzer"
                            }
                        }
                    } else {
                        user?.name ?: "Benutzer"
                    }

                    val currentName = chat.participantNames[participantId]
                    if (currentName == null || currentName == "Benutzer" || currentName == "Unknown User" || currentName.startsWith("User ") || currentName.contains("Unknown")) {
                        updatedParticipantNames[participantId] = assignedName
                    } else {
                        updatedParticipantNames[participantId] = currentName
                    }
                }

                val updatedChat = chat.copy(participantNames = updatedParticipantNames)
                chatRef.set(updatedChat).await()
            }

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun sendMessageWithAttachment(
        chatId: String,
        senderId: String,
        senderName: String,
        content: String = "",
        fileUri: Uri,
        fileName: String,
        fileType: String,
        imageRepository: ImageRepository
    ): Result<Unit> {
        return try {
            val messageId = UUID.randomUUID().toString()

            val uploadResult = when (fileType) {
                "image" -> imageRepository.uploadChatImage(chatId, fileUri)
                else -> imageRepository.uploadChatFile(chatId, fileUri, fileName)
            }

            if (uploadResult.isFailure) {
                return Result.failure(uploadResult.exceptionOrNull() ?: Exception("File upload failed"))
            }

            val (fileUrl, fileSize) = uploadResult.getOrNull() ?: return Result.failure(Exception("Upload result null"))

            val messageType = when (fileType) {
                "image" -> MessageType.IMAGE
                "pdf", "zip" -> MessageType.FILE
                else -> MessageType.FILE
            }

            val message = Message(
                id = messageId,
                chatId = chatId,
                senderId = senderId,
                senderName = senderName,
                content = content.ifEmpty { fileName },
                timestamp = System.currentTimeMillis(),
                type = messageType,
                fileUrl = fileUrl,
                fileName = fileName,
                fileType = fileType,
                fileSize = fileSize
            )

            db.collection("messages").document(messageId).set(message).await()

            updateChatLastMessage(chatId, senderId, message.getDisplayText())

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun sendLinkMessage(
        chatId: String,
        senderId: String,
        senderName: String,
        linkUrl: String,
        description: String = ""
    ): Result<Unit> {
        return try {
            val messageId = UUID.randomUUID().toString()

            val message = Message(
                id = messageId,
                chatId = chatId,
                senderId = senderId,
                senderName = senderName,
                content = description.ifEmpty { linkUrl },
                timestamp = System.currentTimeMillis(),
                type = MessageType.LINK,
                fileUrl = linkUrl,
                fileName = linkUrl
            )

            db.collection("messages").document(messageId).set(message).await()
            updateChatLastMessage(chatId, senderId, "📎 Link gesendet")

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private suspend fun updateChatLastMessage(chatId: String, senderId: String, lastMessageText: String) {
        try {
            val chatRef = db.collection("chats").document(chatId)
            val chatSnapshot = chatRef.get().await()
            val chat = chatSnapshot.toObject(Chat::class.java)

            if (chat != null) {
                val updatedUnreadCount = chat.unreadCount.toMutableMap()
                val updatedTemporaryEmpty = chat.temporaryEmptyForUsers.toMutableList()
                val updatedHiddenUsers = chat.hiddenForUsers.toMutableList()
                val updatedPendingUnhide = chat.pendingUnhideForUsers.toMutableList()
                val updatedConnectionStatus = chat.connectionStatus.toMutableMap()

                updatedTemporaryEmpty.remove(senderId)
                updatedHiddenUsers.remove(senderId)
                updatedPendingUnhide.remove(senderId)

                updatedConnectionStatus[senderId] = ChatConnectionStatus.CONNECTED

                chat.participants.forEach { participantId ->
                    if (participantId != senderId) {
                        updatedUnreadCount[participantId] = (updatedUnreadCount[participantId] ?: 0) + 1
                    }
                }

                val updatedChat = chat.copy(
                    lastMessage = lastMessageText,
                    lastMessageTimestamp = System.currentTimeMillis(),
                    lastMessageSenderId = senderId,
                    unreadCount = updatedUnreadCount,
                    temporaryEmptyForUsers = updatedTemporaryEmpty,
                    hiddenForUsers = updatedHiddenUsers,
                    pendingUnhideForUsers = updatedPendingUnhide,
                    connectionStatus = updatedConnectionStatus
                )

                chatRef.set(updatedChat).await()
            }
        } catch (_: Exception) {
        }
    }

    fun Message.getDisplayText(): String {
        return when (type) {
            MessageType.TEXT -> content
            MessageType.IMAGE -> "📷 Bild"
            MessageType.FILE -> when (fileType) {
                "pdf" -> "📄 PDF-Datei"
                "zip" -> "🗃️ ZIP-Datei"
                else -> "📎 Datei"
            }
            MessageType.LINK -> "🔗 Link"
        }
    }
}