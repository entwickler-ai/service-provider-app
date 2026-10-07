package com.findurdevkotlin.ui.chat

import android.content.Intent
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import coil.compose.AsyncImage
import coil.request.ImageRequest
import com.findurdevkotlin.data.model.Message
import com.findurdevkotlin.data.model.MessageType
import java.text.SimpleDateFormat
import java.util.*
import androidx.core.net.toUri
import com.findurdevkotlin.data.model.ChatConnectionStatus
import com.findurdevkotlin.data.model.ChatDetailState
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatDetailScreen(
    navController: NavController,
    chatId: String,
    viewModel: ChatViewModel = hiltViewModel()
) {
    val chatDetailState by viewModel.chatDetailState.collectAsState()
    val listState = rememberLazyListState()
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var messageText by remember { mutableStateOf("") }
    var showAttachmentDialog by remember { mutableStateOf(false) }
    var showLinkDialog by remember { mutableStateOf(false) }
    var linkUrl by remember { mutableStateOf("") }
    var linkDescription by remember { mutableStateOf("") }
    var showImproveDialog by remember { mutableStateOf(false) }
    var improvedText by remember { mutableStateOf<String?>(null) }
    var isImproving by remember { mutableStateOf(false) }
    var showSummarizeDialog by remember { mutableStateOf(false) }
    var summarizedText by remember { mutableStateOf<String?>(null) }
    var isSummarizing by remember { mutableStateOf(false) }

    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let { viewModel.sendImageMessage(it) }
    }

    val filePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let { fileUri ->
            val fileName = getFileNameFromUri(context, fileUri) ?: "file"
            viewModel.sendFileMessage(fileUri, fileName)
        }
    }

    val shouldShowMessages = remember(chatDetailState.chat, chatDetailState.messages) {
        val chat = chatDetailState.chat
        chat != null && !chat.temporaryEmptyForUsers.contains(viewModel.currentUserId)
    }

    val visibleMessages = if (shouldShowMessages) {
        chatDetailState.messages
    } else {
        emptyList()
    }

    val connectionStatus = remember(chatDetailState.chat) {
        val chat = chatDetailState.chat
        chat?.connectionStatus?.get(viewModel.currentUserId)
    }

    LaunchedEffect(chatId) {
        if (chatId.startsWith("new_chat_")) {
            val otherUserId = chatId.removePrefix("new_chat_")
            viewModel.createOrGetChat(otherUserId)
        } else {
            val chatResult = viewModel.chatRepository.getChatById(chatId)
            if (chatResult.isSuccess) {
                val chat = chatResult.getOrNull()
                viewModel._chatDetailState.value = ChatDetailState(chat = chat)

                if (chat != null && !chat.temporaryEmptyForUsers.contains(viewModel.currentUserId)) {
                    viewModel.loadChatMessages(chatId)
                    viewModel.markMessagesAsRead(chatId)
                }
            }
        }
    }

    LaunchedEffect(visibleMessages.size) {
        if (visibleMessages.isNotEmpty()) {
            listState.animateScrollToItem(visibleMessages.size - 1)
        }
    }

    LaunchedEffect(chatDetailState.chat?.temporaryEmptyForUsers) {
        val chat = chatDetailState.chat
        if (chat != null &&
            !chat.temporaryEmptyForUsers.contains(viewModel.currentUserId) &&
            chatDetailState.messages.isEmpty()) {
            viewModel.loadChatMessages(chat.id)
        }
    }

    DisposableEffect(Unit) {
        onDispose {
            if (!chatId.startsWith("new_chat_")) {
                viewModel.markMessagesAsRead(chatId)
            }
        }
    }

    val otherParticipantName = remember(chatDetailState.chat) {
        val currentUserId = viewModel.currentUserId
        val otherParticipantId = chatDetailState.chat?.participants?.firstOrNull { it != currentUserId }
        chatDetailState.chat?.participantNames?.get(otherParticipantId) ?: "Chat"
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .size(32.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.primary),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Person,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onPrimary,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                        Spacer(modifier = Modifier.width(8.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = otherParticipantName,
                                style = MaterialTheme.typography.titleMedium
                            )
                            if (chatDetailState.chat?.serviceTitle?.isNotEmpty() == true) {
                                Text(
                                    text = "Service: ${chatDetailState.chat!!.serviceTitle}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.outline
                                )
                            }
                        }

                        if (connectionStatus != null) {
                            ConnectionStatusIndicator(status = connectionStatus)
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Zurück")
                    }
                }
            )
        },
        bottomBar = {
            MessageInputBar(
                message = messageText,
                onMessageChange = { messageText = it },
                onSendMessage = {
                    if (messageText.trim().isNotEmpty() && chatDetailState.chat != null) {
                        viewModel.sendMessage(messageText)
                        messageText = ""
                    }
                },
                onAttachmentClick = { showAttachmentDialog = true },
                onImproveClick = {
                    if (messageText.trim().isNotEmpty()) {
                        isImproving = true
                        scope.launch {
                            improvedText = viewModel.openAIService.improveText(messageText, "Chat-Nachricht")
                            isImproving = false
                            if (improvedText != null) {
                                showImproveDialog = true
                            }
                        }
                    }
                },
                isSending = chatDetailState.sendingMessage,
                isUploadingFile = chatDetailState.isUploadingFile,
                isImproving = isImproving,
                enabled = chatDetailState.chat != null
            )
        }
    ) { paddingValues ->
        when {
            chatDetailState.isLoading || chatDetailState.isLoadingMessages -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        CircularProgressIndicator()
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = if (chatDetailState.isLoading) "Chat wird geladen..." else "Nachrichten werden geladen...",
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }
                }
            }

            chatDetailState.error != null -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues)
                        .padding(16.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Card(
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.errorContainer
                        )
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                imageVector = Icons.Default.Error,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onErrorContainer
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = chatDetailState.error!!,
                                color = MaterialTheme.colorScheme.onErrorContainer
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            TextButton(
                                onClick = { viewModel.clearError() }
                            ) {
                                Text("OK")
                            }
                        }
                    }
                }
            }

            chatDetailState.chat == null -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }

            else -> {
                if (visibleMessages.isEmpty() && shouldShowMessages) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(paddingValues),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                } else if (visibleMessages.isEmpty()) {
                    EmptyMessagesView(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(paddingValues)
                    )
                } else {
                    LazyColumn(
                        state = listState,
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(paddingValues),
                        contentPadding = PaddingValues(8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(visibleMessages) { message ->
                            MessageBubble(
                                message = message,
                                viewModel = viewModel,
                                onSummarizeClick = { text ->
                                    isSummarizing = true
                                    scope.launch {
                                        summarizedText = viewModel.openAIService.summarizeText(text)
                                        isSummarizing = false
                                        if (summarizedText != null) {
                                            showSummarizeDialog = true
                                        }
                                    }
                                },
                                isSummarizing = isSummarizing
                            )
                        }
                    }
                }
            }
        }
    }

    if (showAttachmentDialog) {
        AttachmentSelectionDialog(
            onImageClick = {
                imagePickerLauncher.launch("image/*")
                showAttachmentDialog = false
            },
            onFileClick = {
                filePickerLauncher.launch("*/*")
                showAttachmentDialog = false
            },
            onLinkClick = {
                showLinkDialog = true
                showAttachmentDialog = false
            },
            onDismiss = { showAttachmentDialog = false }
        )
    }

    if (showLinkDialog) {
        LinkInputDialog(
            linkUrl = linkUrl,
            linkDescription = linkDescription,
            onUrlChange = { linkUrl = it },
            onDescriptionChange = { linkDescription = it },
            onSend = {
                if (linkUrl.trim().isNotEmpty()) {
                    viewModel.sendLinkMessage(linkUrl.trim(), linkDescription.trim())
                    linkUrl = ""
                    linkDescription = ""
                }
                showLinkDialog = false
            },
            onDismiss = {
                linkUrl = ""
                linkDescription = ""
                showLinkDialog = false
            }
        )
    }

    if (showImproveDialog && improvedText != null) {
        AlertDialog(
            onDismissRequest = { showImproveDialog = false },
            title = { Text("Verbesserter Text") },
            text = { Text(improvedText!!) },
            confirmButton = {
                TextButton(onClick = {
                    messageText = improvedText!!
                    showImproveDialog = false
                }) { Text("Annehmen") }
            },
            dismissButton = {
                TextButton(onClick = { showImproveDialog = false }) { Text("Ablehnen") }
            }
        )
    }

    if (showSummarizeDialog && summarizedText != null) {
        AlertDialog(
            onDismissRequest = { showSummarizeDialog = false },
            title = { Text("Zusammengefasster Text") },
            text = { Text(summarizedText!!) },
            confirmButton = {
                TextButton(onClick = {
                    showSummarizeDialog = false
                }) { Text("Schließen") }
            },
        )
    }
}

@Composable
private fun ConnectionStatusIndicator(status: ChatConnectionStatus) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.padding(end = 8.dp)
    ) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .background(
                    color = when (status) {
                        ChatConnectionStatus.READY -> Color(0xFFF57C00)
                        ChatConnectionStatus.CONNECTED -> Color(0xFF4CAF50)
                    },
                    shape = CircleShape
                )
        )
        Spacer(modifier = Modifier.width(4.dp))
        Text(
            text = when (status) {
                ChatConnectionStatus.READY -> "Bereit"
                ChatConnectionStatus.CONNECTED -> "Verbunden"
            },
            style = MaterialTheme.typography.labelSmall,
            color = when (status) {
                ChatConnectionStatus.READY -> Color(0xFFF57C00)
                ChatConnectionStatus.CONNECTED -> Color(0xFF4CAF50)
            }
        )
    }
}
@Composable
private fun MessageBubble(
    message: Message,
    viewModel: ChatViewModel = hiltViewModel(),
    onSummarizeClick: (String) -> Unit,
    isSummarizing: Boolean
) {
    val currentUserId = viewModel.currentUserId
    val isOwnMessage = message.senderId == currentUserId
    val context = LocalContext.current

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isOwnMessage) {
            Arrangement.End
        } else {
            Arrangement.Start
        }
    ) {
        Card(
            modifier = Modifier.widthIn(max = 280.dp),
            colors = CardDefaults.cardColors(
                containerColor = if (isOwnMessage) {
                    MaterialTheme.colorScheme.primary
                } else {
                    MaterialTheme.colorScheme.surfaceVariant
                }
            ),
            shape = RoundedCornerShape(
                topStart = if (isOwnMessage) 16.dp else 4.dp,
                topEnd = if (isOwnMessage) 4.dp else 16.dp,
                bottomStart = 16.dp,
                bottomEnd = 16.dp
            )
        ) {
            Column(
                modifier = Modifier.padding(12.dp)
            ) {
                when (message.type) {
                    MessageType.IMAGE -> {
                        ImageAttachment(
                            imageUrl = message.fileUrl,
                            onClick = { /* Open full screen */ }
                        )
                        if (message.content.isNotEmpty() && message.content != message.fileName) {
                            Spacer(modifier = Modifier.height(8.dp))
                        }
                    }
                    MessageType.FILE -> {
                        FileAttachment(
                            fileName = message.fileName,
                            fileSize = message.fileSize,
                            fileType = message.fileType,
                            onClick = {
                                openFile(context, message.fileUrl)
                            }
                        )
                        if (message.content.isNotEmpty() && message.content != message.fileName) {
                            Spacer(modifier = Modifier.height(8.dp))
                        }
                    }
                    MessageType.LINK -> {
                        LinkAttachment(
                            url = message.fileUrl,
                            onClick = {
                                openUrl(context, message.fileUrl)
                            }
                        )
                        if (message.content.isNotEmpty() && message.content != message.fileUrl) {
                            Spacer(modifier = Modifier.height(8.dp))
                        }
                    }
                    MessageType.TEXT -> {
                    }
                }

                if ((message.type == MessageType.TEXT) ||
                    (message.content.isNotEmpty() && message.content != message.fileName && message.content != message.fileUrl)) {
                    Text(
                        text = message.content,
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (isOwnMessage) {
                            MaterialTheme.colorScheme.onPrimary
                        } else {
                            MaterialTheme.colorScheme.onSurfaceVariant
                        }
                    )
                }

                Spacer(modifier = Modifier.height(4.dp))

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = if (isOwnMessage) Arrangement.End else Arrangement.SpaceBetween,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    if (!isOwnMessage && message.type == MessageType.TEXT && message.content.isNotEmpty()) {
                        IconButton(
                            onClick = { onSummarizeClick(message.content) },
                            enabled = !isSummarizing
                        ) {
                            Icon(
                                imageVector = Icons.Default.Summarize,
                                contentDescription = "Nachricht zusammenfassen",
                                tint = if (!isSummarizing) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline
                            )
                        }
                    } else {
                        Spacer(modifier = Modifier.width(0.dp))
                    }

                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = formatMessageTimestamp(message.timestamp),
                            style = MaterialTheme.typography.labelSmall,
                            color = if (isOwnMessage) {
                                MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.7f)
                            } else {
                                MaterialTheme.colorScheme.outline
                            }
                        )
                        if (isOwnMessage) {
                            Spacer(modifier = Modifier.width(4.dp))
                            Icon(
                                imageVector = if (message.isRead) Icons.Default.DoneAll else Icons.Default.Done,
                                contentDescription = if (message.isRead) "Gelesen" else "Gesendet",
                                modifier = Modifier.size(12.dp),
                                tint = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.7f)
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ImageAttachment(
    imageUrl: String,
    onClick: () -> Unit
) {
    AsyncImage(
        model = ImageRequest.Builder(LocalContext.current)
            .data(imageUrl)
            .crossfade(true)
            .build(),
        contentDescription = "Bild",
        contentScale = ContentScale.Crop,
        modifier = Modifier
            .fillMaxWidth()
            .height(200.dp)
            .clip(RoundedCornerShape(8.dp))
            .clickable { onClick() }
            .background(MaterialTheme.colorScheme.surfaceVariant)
    )
}

@Composable
private fun FileAttachment(
    fileName: String,
    fileSize: Long,
    fileType: String,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.5f)
        )
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = when (fileType) {
                    "pdf" -> Icons.Default.PictureAsPdf
                    "zip" -> Icons.Default.Archive
                    else -> Icons.Default.AttachFile
                },
                contentDescription = null,
                modifier = Modifier.size(32.dp)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = fileName,
                    style = MaterialTheme.typography.bodyMedium,
                    maxLines = 1
                )
                Text(
                    text = formatFileSize(fileSize),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.outline
                )
            }
            Icon(
                imageVector = Icons.Default.Download,
                contentDescription = "Herunterladen",
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@Composable
private fun LinkAttachment(
    url: String,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.5f)
        )
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Link,
                contentDescription = null,
                modifier = Modifier.size(24.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = url,
                style = MaterialTheme.typography.bodyMedium.copy(
                    textDecoration = TextDecoration.Underline
                ),
                color = MaterialTheme.colorScheme.primary,
                maxLines = 2,
                modifier = Modifier.weight(1f)
            )
            Icon(
                imageVector = Icons.AutoMirrored.Filled.OpenInNew,
                contentDescription = "Öffnen",
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MessageInputBar(
    message: String,
    onMessageChange: (String) -> Unit,
    onSendMessage: () -> Unit,
    onAttachmentClick: () -> Unit,
    onImproveClick: () -> Unit,
    isSending: Boolean,
    isUploadingFile: Boolean,
    isImproving: Boolean,
    enabled: Boolean = true
) {
    Surface(
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 8.dp
    ) {
        Column {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(8.dp),
                verticalAlignment = Alignment.Bottom
            ) {
                IconButton(
                    onClick = onAttachmentClick,
                    enabled = enabled && !isSending && !isUploadingFile && !isImproving
                ) {
                    Icon(
                        imageVector = Icons.Default.AttachFile,
                        contentDescription = "Datei anhängen",
                        tint = if (enabled) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline
                    )
                }

                IconButton(
                    onClick = onImproveClick,
                    enabled = enabled && !isSending && !isUploadingFile && !isImproving && message.trim().isNotEmpty()
                ) {
                    Icon(
                        imageVector = Icons.Default.AutoFixHigh,
                        contentDescription = "Nachricht verbessern",
                        tint = if (enabled && message.trim().isNotEmpty()) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline
                    )
                }

                TextField(
                    value = message,
                    onValueChange = onMessageChange,
                    modifier = Modifier.weight(1f),
                    placeholder = { Text("Nachricht schreiben...") },
                    maxLines = 4,
                    enabled = enabled && !isUploadingFile && !isImproving,
                    shape = RoundedCornerShape(24.dp),
                    colors = TextFieldDefaults.colors(
                        focusedIndicatorColor = Color.Transparent,
                        unfocusedIndicatorColor = Color.Transparent
                    )
                )

                Spacer(modifier = Modifier.width(8.dp))

                FloatingActionButton(
                    onClick = onSendMessage,
                    modifier = Modifier.size(48.dp),
                    containerColor = if (message.trim().isNotEmpty() && enabled && !isUploadingFile && !isImproving) {
                        MaterialTheme.colorScheme.primary
                    } else {
                        MaterialTheme.colorScheme.outline.copy(alpha = 0.3f)
                    }
                ) {
                    when {
                        isSending || isUploadingFile || isImproving -> {
                            CircularProgressIndicator(
                                modifier = Modifier.size(20.dp),
                                color = MaterialTheme.colorScheme.onPrimary,
                                strokeWidth = 2.dp
                            )
                        }
                        else -> {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.Send,
                                contentDescription = "Senden",
                                tint = MaterialTheme.colorScheme.onPrimary
                            )
                        }
                    }
                }
            }

            if (isUploadingFile || isImproving) {
                Row(
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(16.dp),
                        strokeWidth = 2.dp
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = if (isUploadingFile) "Datei wird hochgeladen..." else "Text wird verbessert...",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.outline
                    )
                }
            }
        }
    }
}

@Composable
private fun AttachmentSelectionDialog(
    onImageClick: () -> Unit,
    onFileClick: () -> Unit,
    onLinkClick: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Anhang auswählen") },
        text = {
            Column {
                AttachmentOption(
                    icon = Icons.Default.Photo,
                    title = "Bild",
                    description = "Foto aus Galerie auswählen",
                    onClick = onImageClick
                )
                AttachmentOption(
                    icon = Icons.Default.AttachFile,
                    title = "Datei",
                    description = "PDF, ZIP oder andere Dateien",
                    onClick = onFileClick
                )
                AttachmentOption(
                    icon = Icons.Default.Link,
                    title = "Link",
                    description = "Webseite oder URL teilen",
                    onClick = onLinkClick
                )
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Abbrechen")
            }
        }
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AttachmentOption(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    description: String,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(32.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline
                )
            }
        }
    }
}

@Composable
private fun LinkInputDialog(
    linkUrl: String,
    linkDescription: String,
    onUrlChange: (String) -> Unit,
    onDescriptionChange: (String) -> Unit,
    onSend: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Link teilen") },
        text = {
            Column {
                TextField(
                    value = linkUrl,
                    onValueChange = onUrlChange,
                    label = { Text("URL *") },
                    placeholder = { Text("https://...") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                Spacer(modifier = Modifier.height(8.dp))
                TextField(
                    value = linkDescription,
                    onValueChange = onDescriptionChange,
                    label = { Text("Beschreibung (optional)") },
                    placeholder = { Text("Was ist das für ein Link?") },
                    modifier = Modifier.fillMaxWidth(),
                    maxLines = 3
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = onSend,
                enabled = linkUrl.trim().isNotEmpty()
            ) {
                Text("Senden")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Abbrechen")
            }
        }
    )
}

@Composable
private fun EmptyMessagesView(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.ChatBubbleOutline,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.outline
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "Beginnen Sie die Unterhaltung",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Schreiben Sie die erste Nachricht oder teilen Sie Dateien",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.outline,
                textAlign = TextAlign.Center
            )
        }
    }
}

private fun formatMessageTimestamp(timestamp: Long): String {
    val now = System.currentTimeMillis()
    val diff = now - timestamp

    val calendar = Calendar.getInstance()
    val todayStart = calendar.apply {
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }.timeInMillis

    return when {
        timestamp >= todayStart -> {
            SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(timestamp))
        }
        diff < 7 * 24 * 60 * 60 * 1000 -> {
            SimpleDateFormat("EEE HH:mm", Locale.getDefault()).format(Date(timestamp))
        }
        else -> {
            SimpleDateFormat("dd.MM.yyyy HH:mm", Locale.getDefault()).format(Date(timestamp))
        }
    }
}

private fun formatFileSize(bytes: Long): String {
    return when {
        bytes < 1024 -> "$bytes B"
        bytes < 1024 * 1024 -> "${bytes / 1024} KB"
        bytes < 1024 * 1024 * 1024 -> "${bytes / (1024 * 1024)} MB"
        else -> "${bytes / (1024 * 1024 * 1024)} GB"
    }
}

private fun openFile(context: android.content.Context, url: String) {
    try {
        val intent = Intent(Intent.ACTION_VIEW, url.toUri())
        context.startActivity(intent)
    } catch (_: Exception) {
    }
}

private fun openUrl(context: android.content.Context, url: String) {
    try {
        val intent = Intent(Intent.ACTION_VIEW, url.toUri())
        context.startActivity(intent)
    } catch (_: Exception) {
    }
}

private fun getFileNameFromUri(context: android.content.Context, uri: Uri): String? {
    return try {
        val cursor = context.contentResolver.query(uri, null, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val nameIndex = it.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                if (nameIndex >= 0) {
                    it.getString(nameIndex)
                } else null
            } else null
        }
    } catch (_: Exception) {
        null
    }
}