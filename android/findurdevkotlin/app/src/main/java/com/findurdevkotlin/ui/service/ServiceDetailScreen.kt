package com.findurdevkotlin.ui.service

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Chat
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
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.findurdevkotlin.ui.navigation.Screen
import com.findurdevkotlin.ui.chat.ChatViewModel
import coil.compose.AsyncImage
import coil.request.ImageRequest

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ServiceDetailScreen(
    navController: NavController,
    serviceId: String,
    viewModel: ServiceViewModel = hiltViewModel(),
    chatViewModel: ChatViewModel = hiltViewModel()
) {
    val state by viewModel.serviceDetailState.collectAsState()
    val scrollState = rememberScrollState()

    var showDeleteDialog by remember { mutableStateOf(false) }

    LaunchedEffect(serviceId) {
        viewModel.getServiceById(serviceId)
    }

    LaunchedEffect(state.isDeleted) {
        if (state.isDeleted) {
            navController.popBackStack()
        }
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
                        text = state.service?.title ?: "Service Details",
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Zurück")
                    }
                },
                actions = {
                    if (state.isOwner) {
                        IconButton(onClick = {
                            navController.navigate(Screen.ServiceEdit.createRoute(serviceId))
                        }) {
                            Icon(Icons.Default.Edit, contentDescription = "Bearbeiten")
                        }
                        IconButton(onClick = { showDeleteDialog = true }) {
                            Icon(Icons.Default.Delete, contentDescription = "Löschen")
                        }
                    }
                }
            )
        }
    ) { paddingValues ->
        when {
            state.isLoading -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }

            state.error != null -> {
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
                            text = state.error!!,
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            modifier = Modifier.padding(16.dp)
                        )
                    }
                }
            }

            state.service != null -> {
                ServiceDetailContent(
                    service = state.service!!,
                    provider = state.provider,
                    isOwner = state.isOwner,
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues)
                        .verticalScroll(scrollState),
                    onContactProvider = {
                        chatViewModel.createOrGetChatFromService(
                            otherUserId = state.service!!.providerId,
                            serviceId = state.service!!.id,
                            serviceTitle = state.service!!.title
                        )
                    },
                    onSendRequest = {

                        navController.navigate(
                            Screen.RequestCreate.createRoute(
                                serviceId = state.service!!.id,
                                serviceTitle = state.service!!.title,
                                providerId = state.service!!.providerId,
                                providerName = state.service!!.providerName
                            )
                        )
                    }
                )
            }
        }
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Service löschen") },
            text = { Text("Möchten Sie diesen Service wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteService(serviceId)
                        showDeleteDialog = false
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
private fun ServiceDetailContent(
    service: com.findurdevkotlin.data.model.Service,
    provider: com.findurdevkotlin.data.model.User?,
    isOwner: Boolean,
    modifier: Modifier = Modifier,
    onContactProvider: () -> Unit,
    onSendRequest: () -> Unit
) {
    Column(
        modifier = modifier.padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        ServiceHeaderCard(service = service)

        if (provider != null) {
            ProviderInfoCard(provider = provider)
        }

        if (service.portfolioImages.isNotEmpty()) {
            PortfolioImagesCard(images = service.portfolioImages)
        }

        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = "Beschreibung",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = service.description,
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }

        if (service.tags.isNotEmpty()) {
            TagsCard(tags = service.tags)
        }

        LocationRatingCard(service = service)

        if (!isOwner) {
            CustomerActionButtons(
                onContactProvider = onContactProvider,
                onSendRequest = onSendRequest
            )
        }

        Spacer(modifier = Modifier.height(16.dp))
    }
}

@Composable
private fun ServiceHeaderCard(service: com.findurdevkotlin.data.model.Service) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = service.title,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Euro,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onPrimaryContainer
                )
                Text(
                    text = "${service.price.toInt()}",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
        }
    }
}

@Composable
private fun ProviderInfoCard(provider: com.findurdevkotlin.data.model.User) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier.size(60.dp),
                contentAlignment = Alignment.Center
            ) {
                if (provider.profileImage.isNotEmpty()) {
                    AsyncImage(
                        model = ImageRequest.Builder(LocalContext.current)
                            .data(provider.profileImage)
                            .crossfade(true)
                            .build(),
                        contentDescription = "Profilbild",
                        contentScale = ContentScale.Crop,
                        modifier = Modifier
                            .fillMaxSize()
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.secondary)
                    )
                } else {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.secondary),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Person,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSecondary,
                            modifier = Modifier.size(30.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.width(16.dp))

            Column {
                Text(
                    text = provider.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                if (provider.description.isNotEmpty()) {
                    Text(
                        text = provider.description,
                        style = MaterialTheme.typography.bodyMedium,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                if (provider.location.isNotEmpty()) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.LocationOn,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Text(
                            text = provider.location,
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun PortfolioImagesCard(images: List<String>) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Portfolio",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(12.dp))

            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                items(images) { imageUrl ->
                    PortfolioImageItem(imageUrl = imageUrl)
                }
            }
        }
    }
}

@Composable
private fun PortfolioImageItem(imageUrl: String) {
    AsyncImage(
        model = ImageRequest.Builder(LocalContext.current)
            .data(imageUrl)
            .crossfade(true)
            .build(),
        contentDescription = "Portfolio Bild",
        contentScale = ContentScale.Crop,
        modifier = Modifier
            .size(120.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)
    )
}

@Composable
private fun TagsCard(tags: List<String>) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Tags",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(tags) { tag ->
                    AssistChip(
                        onClick = { },
                        label = { Text(tag) }
                    )
                }
            }
        }
    }
}

@Composable
private fun LocationRatingCard(service: com.findurdevkotlin.data.model.Service) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.LocationOn,
                    contentDescription = null
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = service.location,
                    style = MaterialTheme.typography.bodyMedium
                )
            }

            when {
                service.rating == null || service.rating == 0.0 -> {
                    Icon(
                        imageVector = Icons.Default.Star,
                        contentDescription = null,
                        tint = Color(0xFFFFD700)
                    )
                }
                service.rating > 0.0 -> {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Star,
                            contentDescription = null,
                            tint = Color(0xFFFFD700)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = String.format("%.1f", service.rating),
                            style = MaterialTheme.typography.bodyMedium
                        )
                        if (service.reviewCount > 0) {
                            Text(
                                text = " (${service.reviewCount})",
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CustomerActionButtons(
    onContactProvider: () -> Unit,
    onSendRequest: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Button(
                onClick = onSendRequest,
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.Send,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Anfrage senden")
            }

            OutlinedButton(
                onClick = onContactProvider,
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.Chat,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Nachricht schreiben")
            }
        }
    }
}