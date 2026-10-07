package com.findurdevkotlin.ui.request

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.material3.HorizontalDivider
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.findurdevkotlin.data.model.Request
import com.findurdevkotlin.data.model.RequestStatus
import com.findurdevkotlin.data.model.RequestStatusHistory
import com.findurdevkotlin.data.model.canBeUpdatedBy
import com.findurdevkotlin.data.model.getNextPossibleStatuses
import com.findurdevkotlin.ui.chat.ChatViewModel
import com.findurdevkotlin.ui.navigation.Screen
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RequestDetailScreen(
    navController: NavController,
    requestId: String,
    viewModel: RequestViewModel = hiltViewModel(),
    chatViewModel: ChatViewModel = hiltViewModel()
) {
    val requestDetailState by viewModel.requestDetailState.collectAsState()
    val shouldShowReviewPrompt by viewModel.shouldShowReviewPrompt.collectAsState()
    val scrollState = rememberScrollState()

    var showStatusDialog by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }
    var selectedNewStatus by remember { mutableStateOf<RequestStatus?>(null) }
    var statusResponse by remember { mutableStateOf("") }

    LaunchedEffect(requestId) {
        viewModel.loadRequestDetail(requestId)
    }

    val chatDetailState by chatViewModel.chatDetailState.collectAsState()
    LaunchedEffect(chatDetailState.chat) {
        chatDetailState.chat?.let { chat ->
            navController.navigate(Screen.ChatDetail.createRoute(chat.id))
            chatViewModel.resetChatDetailState()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = requestDetailState.request?.title ?: "Anfrage Details",
                        maxLines = 1
                    )
                },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Zurück")
                    }
                },
                actions = {
                    requestDetailState.request?.let { request ->
                        if (request.customerId == chatViewModel.currentUserId &&
                            request.status == RequestStatus.PENDING) {
                            IconButton(onClick = { showDeleteDialog = true }) {
                                Icon(Icons.Default.Delete, contentDescription = "Löschen")
                            }
                        }
                    }
                }
            )
        }
    ) { paddingValues ->
        when {
            requestDetailState.isLoading -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }

            requestDetailState.error != null -> {
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
                                text = requestDetailState.error!!,
                                color = MaterialTheme.colorScheme.onErrorContainer
                            )
                        }
                    }
                }
            }

            requestDetailState.request != null -> {
                RequestDetailContent(
                    request = requestDetailState.request!!,
                    statusHistory = requestDetailState.statusHistory,
                    isUpdating = requestDetailState.isUpdating,
                    currentUserId = chatViewModel.currentUserId,
                    shouldShowReviewPrompt = shouldShowReviewPrompt,
                    onStatusUpdate = { status ->
                        selectedNewStatus = status
                        showStatusDialog = true
                    },
                    onStartChat = { request ->
                        val otherUserId = if (request.customerId == chatViewModel.currentUserId) {
                            request.providerId
                        } else {
                            request.customerId
                        }

                        chatViewModel.createOrGetChat(
                            otherUserId = otherUserId,
                            serviceId = request.serviceId,
                            serviceTitle = request.serviceTitle
                        )
                    },
                    onReviewClick = {
                        navController.navigate(Screen.CustomerReview.createRoute(requestId))
                        viewModel.dismissReviewPrompt()
                    },
                    onDismissReviewPrompt = {
                        viewModel.dismissReviewPrompt()
                    },
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues)
                        .verticalScroll(scrollState)
                )
            }
        }
    }

    if (showStatusDialog && selectedNewStatus != null) {
        StatusUpdateDialog(
            newStatus = selectedNewStatus!!,
            response = statusResponse,
            onResponseChange = { statusResponse = it },
            onConfirm = {
                viewModel.updateRequestStatus(
                    requestId = requestId,
                    newStatus = selectedNewStatus!!,
                    response = statusResponse
                )
                showStatusDialog = false
                statusResponse = ""
                selectedNewStatus = null
            },
            onDismiss = {
                showStatusDialog = false
                statusResponse = ""
                selectedNewStatus = null
            }
        )
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Anfrage löschen") },
            text = { Text("Möchten Sie diese Anfrage wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteRequest(requestId)
                        showDeleteDialog = false
                        navController.popBackStack()
                    }
                ) {
                    Text("Löschen", color = MaterialTheme.colorScheme.error)
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
private fun RequestDetailContent(
    request: Request,
    statusHistory: List<RequestStatusHistory>,
    isUpdating: Boolean,
    currentUserId: String,
    shouldShowReviewPrompt: Boolean,
    onStatusUpdate: (RequestStatus) -> Unit,
    onStartChat: (Request) -> Unit,
    onReviewClick: () -> Unit,
    onDismissReviewPrompt: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isProvider = request.providerId == currentUserId
    val canUpdate = request.status.canBeUpdatedBy(isProvider)
    val nextStatuses = request.status.getNextPossibleStatuses(isProvider)

    Column(
        modifier = modifier.padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        if (shouldShowReviewPrompt && request.status == RequestStatus.COMPLETED && !isProvider) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.tertiaryContainer
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Star,
                            contentDescription = null,
                            tint = Color(0xFFFFD700),
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Auftrag abgeschlossen!",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onTertiaryContainer
                        )
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    Text(
                        text = "Wie war die Zusammenarbeit mit ${request.providerName}? Teilen Sie Ihre Erfahrung mit anderen!",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onTertiaryContainer
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Button(
                            onClick = onReviewClick,
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Star,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Jetzt bewerten")
                        }

                        OutlinedButton(
                            onClick = onDismissReviewPrompt,
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("Später")
                        }
                    }
                }
            }
        }

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "Status",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                        Text(
                            text = request.status.getDisplayName(),
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    }

                    OutlinedButton(
                        onClick = { onStartChat(request) }
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.Chat,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Chat")
                    }
                }

                if (nextStatuses.isNotEmpty() && canUpdate && !isUpdating) {
                    Spacer(modifier = Modifier.height(12.dp))
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(nextStatuses) { status ->
                            Button(
                                onClick = { onStatusUpdate(status) },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = when (status) {
                                        RequestStatus.ACCEPTED -> MaterialTheme.colorScheme.primary
                                        RequestStatus.REJECTED -> MaterialTheme.colorScheme.error
                                        RequestStatus.CANCELLED -> MaterialTheme.colorScheme.error
                                        else -> MaterialTheme.colorScheme.secondary
                                    }
                                )
                            ) {
                                Text(status.getDisplayName())
                            }
                        }
                    }
                }

                if (isUpdating) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(16.dp),
                            strokeWidth = 2.dp
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Status wird aktualisiert...",
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            }
        }

        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = "Beteiligte",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(8.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column {
                        Text(
                            text = "Kunde",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.outline
                        )
                        Text(
                            text = request.customerName,
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Medium
                        )
                    }

                    Column {
                        Text(
                            text = "Dienstleister",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.outline
                        )
                        Text(
                            text = request.providerName,
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))
                HorizontalDivider(Modifier, DividerDefaults.Thickness, DividerDefaults.color)
                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = "Service",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.outline
                )
                Text(
                    text = request.serviceTitle,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium
                )
            }
        }

        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = "Projektdetails",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(12.dp))

                Text(
                    text = request.description,
                    style = MaterialTheme.typography.bodyMedium
                )

                if (request.requirements.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        text = "Anforderungen",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.outline
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    request.requirements.forEach { requirement ->
                        Row(
                            modifier = Modifier.padding(vertical = 2.dp)
                        ) {
                            Text("• ", color = MaterialTheme.colorScheme.outline)
                            Text(
                                text = requirement,
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                    }
                }
            }
        }

        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "Budget",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.outline
                    )
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Euro,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Text(
                            text = "${request.budget.toInt()}",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                Column {
                    Text(
                        text = "Zeitrahmen",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.outline
                    )
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Schedule,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = request.timeline,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }

        if (request.providerResponse.isNotEmpty()) {
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(
                        text = "Antwort des Dienstleisters",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = request.providerResponse,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        }

        if (statusHistory.isNotEmpty()) {
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(
                        text = "Verlauf",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(8.dp))

                    statusHistory.forEach { history ->
                        StatusHistoryItem(history = history)
                        if (history != statusHistory.last()) {
                            Spacer(modifier = Modifier.height(8.dp))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun StatusHistoryItem(history: RequestStatusHistory) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.Top
    ) {
        Surface(
            color = MaterialTheme.colorScheme.primary,
            shape = RoundedCornerShape(50),
            modifier = Modifier.size(8.dp)
        ) {}

        Spacer(modifier = Modifier.width(12.dp))

        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = history.status.getDisplayName(),
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium
            )
            if (history.notes.isNotEmpty()) {
                Text(
                    text = history.notes,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline
                )
            }
            Text(
                text = SimpleDateFormat("dd.MM.yyyy HH:mm", Locale.getDefault())
                    .format(Date(history.timestamp)),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.outline
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun StatusUpdateDialog(
    newStatus: RequestStatus,
    response: String,
    onResponseChange: (String) -> Unit,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text("Status ändern zu: ${newStatus.getDisplayName()}")
        },
        text = {
            Column {
                Text("Möchten Sie eine Nachricht hinzufügen?")
                Spacer(modifier = Modifier.height(8.dp))
                TextField(
                    value = response,
                    onValueChange = onResponseChange,
                    placeholder = { Text("Optionale Nachricht...") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 2,
                    maxLines = 4
                )
            }
        },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text("Bestätigen")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Abbrechen")
            }
        }
    )
}