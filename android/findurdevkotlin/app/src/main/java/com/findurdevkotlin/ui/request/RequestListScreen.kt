package com.findurdevkotlin.ui.request

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.SendAndArchive
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.findurdevkotlin.data.model.Request
import com.findurdevkotlin.data.model.RequestStatus
import com.findurdevkotlin.ui.navigation.Screen
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RequestListScreen(
    navController: NavController,
    isProvider: Boolean = false,
    viewModel: RequestViewModel = hiltViewModel()
) {
    val requestState by viewModel.requestState.collectAsState()

    var selectedStatusFilter by remember { mutableStateOf<RequestStatus?>(null) }

    var isInitialLoadDone by remember { mutableStateOf(false) }

    LaunchedEffect(isProvider) {
        if (!isInitialLoadDone) {
            if (selectedStatusFilter != null) {
                viewModel.loadRequestsByStatus(selectedStatusFilter!!, isProvider)
            } else {
                viewModel.loadUserRequests(isProvider)
            }

            if (!isProvider) {
                viewModel.markRequestUpdatesAsRead()
            }

            isInitialLoadDone = true
        }
    }

    LaunchedEffect(selectedStatusFilter) {
        if (isInitialLoadDone) {
            if (selectedStatusFilter != null) {
                viewModel.loadRequestsByStatus(selectedStatusFilter!!, isProvider)
            } else {
                viewModel.loadUserRequests(isProvider)
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        if (isProvider) "Anfragen an mich" else "Meine Anfragen"
                    )
                },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Zurück")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            StatusFilterRow(
                selectedStatus = selectedStatusFilter,
                onStatusSelected = { status ->
                    selectedStatusFilter = if (selectedStatusFilter == status) null else status
                },
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
            )

            when {
                requestState.isLoading -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            CircularProgressIndicator()
                            Spacer(modifier = Modifier.height(8.dp))
                            Text("Anfragen werden geladen...")
                        }
                    }
                }

                requestState.error != null -> {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
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
                                    text = requestState.error!!,
                                    color = MaterialTheme.colorScheme.onErrorContainer
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                TextButton(
                                    onClick = {
                                        if (selectedStatusFilter != null) {
                                            viewModel.loadRequestsByStatus(selectedStatusFilter!!, isProvider)
                                        } else {
                                            viewModel.loadUserRequests(isProvider)
                                        }
                                    }
                                ) {
                                    Text("Erneut versuchen")
                                }
                            }
                        }
                    }
                }

                requestState.requests.isEmpty() -> {
                    EmptyRequestsView(
                        isProvider = isProvider,
                        selectedStatus = selectedStatusFilter
                    )
                }

                else -> {
                    LazyColumn(
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        item {
                            Text(
                                text = "${requestState.requests.size} ${if (selectedStatusFilter != null) selectedStatusFilter!!.getDisplayName() else ""}Anfragen",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.outline,
                                modifier = Modifier.padding(bottom = 8.dp)
                            )
                        }

                        val uniqueRequests = requestState.requests
                            .distinctBy { it.id }
                            .filter { it.id.isNotEmpty() }

                        items(
                            items = uniqueRequests,
                            key = { request -> request.id }
                        ) { request ->
                            val isNewUpdate = if (!isProvider) {
                                request.updatedAt > System.currentTimeMillis() - (24 * 60 * 60 * 1000) &&
                                        request.status in listOf(RequestStatus.ACCEPTED, RequestStatus.REJECTED, RequestStatus.COMPLETED) &&
                                        request.updatedAt != request.createdAt
                            } else {
                                false
                            }

                            RequestCard(
                                request = request,
                                isProvider = isProvider,
                                isNewUpdate = isNewUpdate,
                                onClick = {
                                    navController.navigate(Screen.RequestDetail.createRoute(request.id))
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    DisposableEffect(Unit) {
        onDispose {
            viewModel.resetState()
        }
    }
}

@Composable
private fun StatusFilterRow(
    selectedStatus: RequestStatus?,
    onStatusSelected: (RequestStatus) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyRow(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(RequestStatus.entries.toTypedArray()) { status ->
            FilterChip(
                onClick = { onStatusSelected(status) },
                label = { Text(status.getDisplayName()) },
                selected = selectedStatus == status,
                leadingIcon = if (selectedStatus == status) {
                    { Icon(Icons.Default.Check, contentDescription = null, modifier = Modifier.size(16.dp)) }
                } else null
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun RequestCard(
    request: Request,
    isProvider: Boolean,
    isNewUpdate: Boolean = false,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = if (isNewUpdate) {
            CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
            )
        } else {
            CardDefaults.cardColors()
        }
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = request.title,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.weight(1f),
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis
                        )

                        if (isNewUpdate && !isProvider) {
                            Spacer(modifier = Modifier.width(8.dp))
                            Surface(
                                color = MaterialTheme.colorScheme.error,
                                shape = RoundedCornerShape(12.dp)
                            ) {
                                Text(
                                    text = "NEU",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onError,
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.width(8.dp))

                RequestStatusChip(status = request.status)
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Service: ${request.serviceTitle}",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.primary,
                fontWeight = FontWeight.Medium
            )

            Text(
                text = if (isProvider) "von ${request.customerName}" else "an ${request.providerName}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.outline
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = request.description,
                style = MaterialTheme.typography.bodyMedium,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Bottom
            ) {
                Column {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Euro,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = MaterialTheme.colorScheme.outline
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = "${request.budget.toInt()}",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.outline
                        )

                        Spacer(modifier = Modifier.width(12.dp))

                        Icon(
                            imageVector = Icons.Default.Schedule,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = MaterialTheme.colorScheme.outline
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = request.timeline,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.outline
                        )
                    }
                }

                Column {
                    Text(
                        text = formatDate(request.createdAt),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.outline
                    )

                    if (request.updatedAt != request.createdAt) {
                        Text(
                            text = "Aktualisiert: ${formatDate(request.updatedAt)}",
                            style = MaterialTheme.typography.labelSmall,
                            color = if (isNewUpdate) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline,
                            fontWeight = if (isNewUpdate) FontWeight.Medium else FontWeight.Normal
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun RequestStatusChip(status: RequestStatus) {
    val (backgroundColor, contentColor) = when (status) {
        RequestStatus.PENDING -> warning to onWarning
        RequestStatus.ACCEPTED -> MaterialTheme.colorScheme.primary to MaterialTheme.colorScheme.onPrimary
        RequestStatus.REJECTED -> MaterialTheme.colorScheme.error to MaterialTheme.colorScheme.onError
        RequestStatus.IN_PROGRESS -> MaterialTheme.colorScheme.secondary to MaterialTheme.colorScheme.onSecondary
        RequestStatus.COMPLETED -> MaterialTheme.colorScheme.tertiary to MaterialTheme.colorScheme.onTertiary
        RequestStatus.CANCELLED -> MaterialTheme.colorScheme.outline to MaterialTheme.colorScheme.onSurface
    }

    Surface(
        color = backgroundColor,
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier.clip(RoundedCornerShape(12.dp))
    ) {
        Text(
            text = status.getDisplayName(),
            style = MaterialTheme.typography.labelSmall,
            color = contentColor,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
private fun EmptyRequestsView(
    isProvider: Boolean,
    selectedStatus: RequestStatus?
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Card(
            modifier = Modifier.padding(24.dp)
        ) {
            Column(
                modifier = Modifier.padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(
                    imageVector = when {
                        selectedStatus != null -> Icons.Default.FilterList
                        isProvider -> Icons.Default.RequestQuote
                        else -> Icons.AutoMirrored.Filled.SendAndArchive
                    },
                    contentDescription = null,
                    modifier = Modifier.size(64.dp),
                    tint = MaterialTheme.colorScheme.outline
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = when {
                        selectedStatus != null -> "Keine ${selectedStatus.getDisplayName()} Anfragen"
                        isProvider -> "Keine Anfragen erhalten"
                        else -> "Noch keine Anfragen gesendet"
                    },
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = when {
                        selectedStatus != null -> "Es gibt keine Anfragen mit diesem Status."
                        isProvider -> "Sobald Kunden Ihre Services anfragen, erscheinen sie hier."
                        else -> "Durchsuchen Sie Services und senden Sie Ihre erste Anfrage."
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.outline
                )
            }
        }
    }
}

private val warning: Color
    get() = Color(0xFFFFC107)

private val onWarning: Color
    get() = Color(0xFF000000)

private fun formatDate(timestamp: Long): String {
    val now = System.currentTimeMillis()
    val diff = now - timestamp

    val calendar = Calendar.getInstance()
    val todayStart = calendar.apply {
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }.timeInMillis

    val yesterdayStart = todayStart - 24 * 60 * 60 * 1000

    return when {
        timestamp >= todayStart -> "Heute"
        timestamp >= yesterdayStart -> "Gestern"
        diff < 7 * 24 * 60 * 60 * 1000 -> {
            SimpleDateFormat("EEEE", Locale.getDefault()).format(Date(timestamp))
        }
        else -> {
            SimpleDateFormat("dd.MM.yy", Locale.getDefault()).format(Date(timestamp))
        }
    }
}