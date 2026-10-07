package com.findurdevkotlin.ui.chat

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.findurdevkotlin.data.model.Chat
import com.findurdevkotlin.ui.navigation.Screen
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatListScreen(
    navController: NavController,
    viewModel: ChatViewModel = hiltViewModel()
) {
    val chatState by viewModel.chatState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.migrateAllChatsNames()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Nachrichten") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Zurück")
                    }
                }
            )
        }
    ) { paddingValues ->
        when {
            chatState.isLoading -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }

            chatState.error != null -> {
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
                        Text(
                            text = chatState.error!!,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            modifier = Modifier.padding(16.dp)
                        )
                    }
                }
            }

            chatState.chats.isEmpty() -> {
                EmptyChatsView()
            }

            else -> {
                LazyColumn(
                    modifier = Modifier.padding(paddingValues),
                    contentPadding = PaddingValues(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(
                        items = chatState.chats,
                        key = { chat -> chat.id }
                    ) { chat ->
                        ChatListItem(
                            chat = chat,
                            onClick = {
                                navController.navigate(Screen.ChatDetail.createRoute(chat.id))
                            },
                            onDelete = {
                                viewModel.deleteChat(chat.id)
                            },
                            viewModel = viewModel
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ChatListItem(
    chat: Chat,
    onClick: () -> Unit,
    onDelete: () -> Unit,
    viewModel: ChatViewModel = hiltViewModel()
) {
    val currentUserId = viewModel.currentUserId
    val otherParticipantId = chat.participants.firstOrNull { it != currentUserId } ?: ""

    val otherParticipantName = remember(chat.participantNames, otherParticipantId) {
        val name = chat.participantNames[otherParticipantId]
        name ?: "Benutzer"
    }

    val unreadCount = chat.unreadCount[currentUserId] ?: 0
    val hasUnread = unreadCount > 0

    var showDeleteDialog by remember { mutableStateOf(false) }

    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(50.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primary),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onPrimary,
                    modifier = Modifier.size(24.dp)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = otherParticipantName,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = if (hasUnread) FontWeight.Bold else FontWeight.Normal,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                if (chat.lastMessage.isNotEmpty()) {
                    Text(
                        text = chat.lastMessage,
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (hasUnread) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.outline,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                if (chat.serviceTitle.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(2.dp))
                    Surface(
                        color = MaterialTheme.colorScheme.primaryContainer,
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Text(
                            text = "Service: ${chat.serviceTitle}",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onPrimaryContainer,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }
                }
            }

            Column(
                horizontalAlignment = Alignment.End
            ) {
                if (hasUnread) {
                    Badge {
                        Text(
                            text = if (unreadCount > 99) "99+" else unreadCount.toString(),
                            style = MaterialTheme.typography.labelSmall
                        )
                    }
                }

                Spacer(modifier = Modifier.height(4.dp))

                IconButton(
                    onClick = { showDeleteDialog = true },
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = "Chat verstecken",
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.error
                    )
                }

                if (chat.lastMessageTimestamp > 0) {
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = formatDateTime(chat.lastMessageTimestamp),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.outline,
                        textAlign = TextAlign.End,
                        lineHeight = MaterialTheme.typography.labelSmall.lineHeight
                    )
                }
            }
        }
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Chat verstecken") },
            text = { Text("Möchten Sie diesen Chat aus Ihrer Liste entfernen? Der Chat bleibt für den anderen Teilnehmer sichtbar.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        onDelete()
                        showDeleteDialog = false
                    }
                ) {
                    Text("Verstecken", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("Abbrechen")
                }
            }
        )
    }
}

@Composable
private fun EmptyChatsView() {
    Box(
        modifier = Modifier.fillMaxSize(),
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
                text = "Keine Nachrichten",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Starten Sie eine Unterhaltung mit einem Dienstleister",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.outline
            )
        }
    }
}
private fun formatDateTime(timestamp: Long): String {
    val date = Date(timestamp)
    val calendar = Calendar.getInstance()
    val now = Calendar.getInstance()

    calendar.time = date

    val todayStart = Calendar.getInstance().apply {
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }

    val yesterdayStart = Calendar.getInstance().apply {
        time = todayStart.time
        add(Calendar.DAY_OF_YEAR, -1)
    }

    val weekStart = Calendar.getInstance().apply {
        time = todayStart.time
        set(Calendar.DAY_OF_WEEK, firstDayOfWeek)
    }

    return when {
        timestamp >= todayStart.timeInMillis -> {
            val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
            "Heute ${timeFormat.format(date)}"
        }

        timestamp >= yesterdayStart.timeInMillis -> {
            val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
            "Gestern ${timeFormat.format(date)}"
        }

        timestamp >= weekStart.timeInMillis -> {
            val dayTimeFormat = SimpleDateFormat("EEEE HH:mm", Locale.GERMAN)
            dayTimeFormat.format(date)
        }

        else -> {
            val dateFormat = SimpleDateFormat("dd.MM.yyyy", Locale.getDefault())
            val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
            "${dateFormat.format(date)}\n${timeFormat.format(date)}"
        }
    }
}