package com.findurdevkotlin.ui.chat

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.findurdevkotlin.data.model.Chat
import com.findurdevkotlin.data.model.ChatDetailState
import com.findurdevkotlin.data.model.ChatState
import com.findurdevkotlin.data.repository.AuthRepository
import com.findurdevkotlin.data.repository.ChatRepository
import com.findurdevkotlin.data.repository.ImageRepository
import com.findurdevkotlin.data.repository.OpenAIService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ChatViewModel @Inject constructor(
    val chatRepository: ChatRepository,
    private val authRepository: AuthRepository,
    private val imageRepository: ImageRepository,
    val openAIService: OpenAIService
) : ViewModel() {

    private val _chatState = MutableStateFlow(ChatState())
    val chatState: StateFlow<ChatState> = _chatState

    val _chatDetailState = MutableStateFlow(ChatDetailState())
    val chatDetailState: StateFlow<ChatDetailState> = _chatDetailState

    private val _totalUnreadCount = MutableStateFlow(0)
    val totalUnreadCount: StateFlow<Int> = _totalUnreadCount

    val currentUserId = authRepository.getCurrentUser()?.uid ?: ""

    init {
        if (currentUserId.isNotEmpty()) {
            loadUserChats()
            loadTotalUnreadCount()
        }
    }

    private fun loadUserChats() {
        viewModelScope.launch {
            _chatState.value = ChatState(isLoading = true)

            chatRepository.getUserChats(currentUserId)
                .catch { error ->
                    _chatState.value = ChatState(error = error.message)
                }
                .collectLatest { chats ->
                    _chatState.value = ChatState(chats = chats)
                    updateTotalUnreadCount(chats)
                }
        }
    }

    private fun updateTotalUnreadCount(chats: List<Chat>) {
        val totalUnread = chats.sumOf { chat ->
            chat.unreadCount[currentUserId] ?: 0
        }
        _totalUnreadCount.value = totalUnread
    }

    private fun loadTotalUnreadCount() {
        viewModelScope.launch {
            val result = chatRepository.getTotalUnreadCount(currentUserId)
            if (result.isSuccess) {
                _totalUnreadCount.value = result.getOrNull() ?: 0
            }
        }
    }

    fun createOrGetChat(
        otherUserId: String,
        serviceId: String? = null,
        serviceTitle: String? = null
    ) {
        viewModelScope.launch {
            _chatDetailState.value = ChatDetailState(isLoading = true)

            val result = chatRepository.createOrGetChat(
                currentUserId = currentUserId,
                otherUserId = otherUserId,
                serviceId = serviceId,
                serviceTitle = serviceTitle
            )

            if (result.isSuccess) {
                val chat = result.getOrNull()
                _chatDetailState.value = ChatDetailState(chat = chat)
                if (chat != null) {
                    loadChatMessages(chat.id)
                }
            } else {
                _chatDetailState.value = ChatDetailState(
                    error = result.exceptionOrNull()?.message
                )
            }
        }
    }

    fun createOrGetChatFromService(
        otherUserId: String,
        serviceId: String? = null,
        serviceTitle: String? = null
    ) {
        viewModelScope.launch {
            _chatDetailState.value = ChatDetailState(isLoading = true)

            try {
                val result = chatRepository.createOrGetChat(
                    currentUserId = currentUserId,
                    otherUserId = otherUserId,
                    serviceId = serviceId,
                    serviceTitle = serviceTitle
                )

                if (result.isSuccess) {
                    val chat = result.getOrNull()
                    if (chat != null) {
                        if (chat.hiddenForUsers.contains(currentUserId)) {
                            chatRepository.prepareHiddenChatForWriting(chat.id, currentUserId)

                            val updatedChatResult = chatRepository.getChatById(chat.id)
                            if (updatedChatResult.isSuccess) {
                                _chatDetailState.value = ChatDetailState(chat = updatedChatResult.getOrNull())
                            }
                        } else {
                            _chatDetailState.value = ChatDetailState(chat = chat)
                            loadChatMessages(chat.id)
                        }
                    }
                } else {
                    _chatDetailState.value = ChatDetailState(
                        error = result.exceptionOrNull()?.message
                    )
                }
            } catch (e: Exception) {
                _chatDetailState.value = ChatDetailState(error = e.message)
            }
        }
    }

    fun loadChatMessagesForExistingChat(chatId: String) {
        viewModelScope.launch {
            _chatDetailState.value = _chatDetailState.value.copy(isLoadingMessages = true)

            try {
                val chatSnapshot = chatRepository.getChatById(chatId)
                if (chatSnapshot.isSuccess) {
                    val chat = chatSnapshot.getOrNull()

                    if (chat != null) {
                        val refreshResult = chatRepository.refreshChatParticipantNames(chatId, currentUserId)
                        if (refreshResult.isSuccess) {
                            val updatedChat = chatRepository.getChatById(chatId).getOrNull()
                            _chatDetailState.value = _chatDetailState.value.copy(chat = updatedChat)
                        } else {
                            _chatDetailState.value = _chatDetailState.value.copy(chat = chat)
                        }

                        loadChatMessages(chatId)
                    } else {
                        _chatDetailState.value = _chatDetailState.value.copy(
                            isLoadingMessages = false,
                            error = "Chat nicht gefunden"
                        )
                    }
                } else {
                    _chatDetailState.value = _chatDetailState.value.copy(
                        isLoadingMessages = false,
                        error = "Fehler beim Laden des Chats"
                    )
                }
            } catch (e: Exception) {
                _chatDetailState.value = _chatDetailState.value.copy(
                    isLoadingMessages = false,
                    error = e.message
                )
            }
        }
    }

    fun loadChatMessages(chatId: String) {
        viewModelScope.launch {
            _chatDetailState.value = _chatDetailState.value.copy(isLoadingMessages = true)

            chatRepository.getChatMessages(chatId)
                .catch { error ->
                    _chatDetailState.value = _chatDetailState.value.copy(
                        isLoadingMessages = false,
                        error = error.message
                    )
                }
                .collectLatest { messages ->
                    _chatDetailState.value = _chatDetailState.value.copy(
                        messages = messages,
                        isLoadingMessages = false
                    )
                }
        }
    }
    fun sendMessage(content: String) {
        val currentChat = _chatDetailState.value.chat ?: return
        val currentUser = authRepository.getCurrentUser() ?: return

        if (content.trim().isEmpty()) return

        viewModelScope.launch {
            _chatDetailState.value = _chatDetailState.value.copy(sendingMessage = true)

            val currentUserName = getCurrentUserName()

            val result = chatRepository.sendMessage(
                chatId = currentChat.id,
                senderId = currentUser.uid,
                senderName = currentUserName,
                content = content.trim()
            )

            _chatDetailState.value = _chatDetailState.value.copy(sendingMessage = false)

            if (result.isSuccess) {
                refreshChatAndMessages(currentChat.id)
            } else {
                _chatDetailState.value = _chatDetailState.value.copy(
                    error = result.exceptionOrNull()?.message
                )
            }
        }
    }

    fun sendImageMessage(imageUri: Uri, description: String = "") {
        val currentChat = _chatDetailState.value.chat ?: return
        val currentUser = authRepository.getCurrentUser() ?: return

        viewModelScope.launch {
            _chatDetailState.value = _chatDetailState.value.copy(isUploadingFile = true)

            try {
                val currentUserName = getCurrentUserName()

                val result = chatRepository.sendMessageWithAttachment(
                    chatId = currentChat.id,
                    senderId = currentUser.uid,
                    senderName = currentUserName,
                    content = description,
                    fileUri = imageUri,
                    fileName = "image.jpg",
                    fileType = "image",
                    imageRepository = imageRepository
                )

                _chatDetailState.value = _chatDetailState.value.copy(isUploadingFile = false)

                if (result.isSuccess) {
                    refreshChatAndMessages(currentChat.id)
                } else {
                    _chatDetailState.value = _chatDetailState.value.copy(
                        error = result.exceptionOrNull()?.message
                    )
                }
            } catch (e: Exception) {
                _chatDetailState.value = _chatDetailState.value.copy(
                    isUploadingFile = false,
                    error = e.message
                )
            }
        }
    }

    fun sendFileMessage(fileUri: Uri, fileName: String, description: String = "") {
        val currentChat = _chatDetailState.value.chat ?: return
        val currentUser = authRepository.getCurrentUser() ?: return

        viewModelScope.launch {
            _chatDetailState.value = _chatDetailState.value.copy(isUploadingFile = true)

            try {
                val currentUserName = getCurrentUserName()
                val fileType = getFileTypeFromName(fileName)

                val result = chatRepository.sendMessageWithAttachment(
                    chatId = currentChat.id,
                    senderId = currentUser.uid,
                    senderName = currentUserName,
                    content = description,
                    fileUri = fileUri,
                    fileName = fileName,
                    fileType = fileType,
                    imageRepository = imageRepository
                )

                _chatDetailState.value = _chatDetailState.value.copy(isUploadingFile = false)

                if (result.isSuccess) {
                    refreshChatAndMessages(currentChat.id)
                } else {
                    _chatDetailState.value = _chatDetailState.value.copy(
                        error = result.exceptionOrNull()?.message
                    )
                }
            } catch (e: Exception) {
                _chatDetailState.value = _chatDetailState.value.copy(
                    isUploadingFile = false,
                    error = e.message
                )
            }
        }
    }

    fun sendLinkMessage(linkUrl: String, description: String = "") {
        val currentChat = _chatDetailState.value.chat ?: return
        val currentUser = authRepository.getCurrentUser() ?: return

        if (!isValidUrl(linkUrl)) {
            _chatDetailState.value = _chatDetailState.value.copy(
                error = "Ungültige URL"
            )
            return
        }

        viewModelScope.launch {
            _chatDetailState.value = _chatDetailState.value.copy(sendingMessage = true)

            try {
                val currentUserName = getCurrentUserName()

                val result = chatRepository.sendLinkMessage(
                    chatId = currentChat.id,
                    senderId = currentUser.uid,
                    senderName = currentUserName,
                    linkUrl = linkUrl,
                    description = description
                )

                _chatDetailState.value = _chatDetailState.value.copy(sendingMessage = false)

                if (result.isSuccess) {
                    refreshChatAndMessages(currentChat.id)
                } else {
                    _chatDetailState.value = _chatDetailState.value.copy(
                        error = result.exceptionOrNull()?.message
                    )
                }
            } catch (e: Exception) {
                _chatDetailState.value = _chatDetailState.value.copy(
                    sendingMessage = false,
                    error = e.message
                )
            }
        }
    }

    private suspend fun refreshChatAndMessages(chatId: String) {
        try {
            val updatedChatResult = chatRepository.getChatById(chatId)
            if (updatedChatResult.isSuccess) {
                val updatedChat = updatedChatResult.getOrNull()
                _chatDetailState.value = _chatDetailState.value.copy(chat = updatedChat)

                if (updatedChat != null && !updatedChat.temporaryEmptyForUsers.contains(currentUserId)) {
                    loadChatMessages(chatId)
                }
            }
        } catch (e: Exception) {
            _chatDetailState.value = _chatDetailState.value.copy(error = e.message)
        }
    }

    fun markMessagesAsRead(chatId: String) {
        viewModelScope.launch {
            val result = chatRepository.markMessagesAsRead(chatId, currentUserId)
            if (result.isSuccess) {
                loadTotalUnreadCount()
            }
        }
    }

    fun deleteChat(chatId: String) {
        viewModelScope.launch {
            val result = chatRepository.deleteChat(chatId, currentUserId)
            if (result.isSuccess) {
                loadUserChats()
            }
        }
    }

    fun migrateAllChatsNames() {
        viewModelScope.launch {
            val result = chatRepository.migrateAllChatsNames()
            if (result.isSuccess) {
                loadUserChats()
            }
        }
    }

    private suspend fun getCurrentUserName(): String {
        return try {
            val userResult = authRepository.getCurrentUserInfo()
            if (userResult.isSuccess) {
                val user = userResult.getOrNull()
                user?.name ?: "Benutzer"
            } else {
                "Benutzer"
            }
        } catch (_: Exception) {
            "Benutzer"
        }
    }

    private fun getFileTypeFromName(fileName: String): String {
        return when (fileName.substringAfterLast(".", "").lowercase()) {
            "pdf" -> "pdf"
            "zip", "rar", "7z" -> "zip"
            "jpg", "jpeg", "png", "gif", "webp" -> "image"
            else -> "file"
        }
    }

    private fun isValidUrl(url: String): Boolean {
        return url.startsWith("http://") || url.startsWith("https://") || url.startsWith("www.")
    }

    fun clearError() {
        _chatDetailState.value = _chatDetailState.value.copy(error = null)
    }

    fun resetChatDetailState() {
        _chatDetailState.value = ChatDetailState()
    }
}