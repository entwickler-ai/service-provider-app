package com.findurdevkotlin.data.model

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

@Parcelize
data class Chat(
    val id: String = "",
    val participants: List<String> = emptyList(),
    val participantNames: Map<String, String> = emptyMap(),
    val lastMessage: String = "",
    val lastMessageTimestamp: Long = 0L,
    val lastMessageSenderId: String = "",
    val unreadCount: Map<String, Int> = emptyMap(),
    val serviceId: String = "",
    val serviceTitle: String = "",
    val hiddenForUsers: List<String> = emptyList(),
    val temporaryEmptyForUsers: List<String> = emptyList(),
    val pendingUnhideForUsers: List<String> = emptyList(),
    val connectionStatus: Map<String, ChatConnectionStatus> = emptyMap()
) : Parcelable

enum class ChatConnectionStatus {
    READY,
    CONNECTED
}

@Parcelize
data class Message(
    val id: String = "",
    val chatId: String = "",
    val senderId: String = "",
    val senderName: String = "",
    val content: String = "",
    val timestamp: Long = System.currentTimeMillis(),
    val type: MessageType = MessageType.TEXT,
    val fileUrl: String = "",
    val fileName: String = "",
    val fileType: String = "",
    val fileSize: Long = 0L,
    val isRead: Boolean = false
) : Parcelable

enum class MessageType {
    TEXT,
    IMAGE,
    FILE,
    LINK
}

data class ChatState(
    val isLoading: Boolean = false,
    val chats: List<Chat> = emptyList(),
    val error: String? = null
)

data class ChatDetailState(
    val isLoading: Boolean = false,
    val chat: Chat? = null,
    val messages: List<Message> = emptyList(),
    val error: String? = null,
    val isLoadingMessages: Boolean = false,
    val sendingMessage: Boolean = false,
    val isUploadingFile: Boolean = false
)