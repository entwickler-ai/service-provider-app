package com.findurdevkotlin.ui.service

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import coil.compose.AsyncImage
import coil.request.ImageRequest

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ServiceEditScreen(
    navController: NavController,
    serviceId: String,
    viewModel: ServiceViewModel = hiltViewModel()
) {
    val detailState by viewModel.serviceDetailState.collectAsState()
    val serviceState by viewModel.serviceState.collectAsState()
    val scrollState = rememberScrollState()

    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var price by remember { mutableStateOf("") }
    var tags by remember { mutableStateOf("") }
    var location by remember { mutableStateOf("") }
    var existingImages by remember { mutableStateOf<List<String>>(emptyList()) }
    var newImageUris by remember { mutableStateOf<List<Uri>>(emptyList()) }

    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetMultipleContents()
    ) { uris ->
        if (uris.isNotEmpty()) {
            val currentNewImages = newImageUris.toMutableList()
            val totalImages = existingImages.size + currentNewImages.size
            val availableSlots = 5 - totalImages
            val imagesToAdd = uris.take(availableSlots)
            currentNewImages.addAll(imagesToAdd)
            newImageUris = currentNewImages
        }
    }

    LaunchedEffect(serviceId) {
        viewModel.getServiceById(serviceId)
    }

    LaunchedEffect(detailState.service) {
        detailState.service?.let { service ->
            title = service.title
            description = service.description
            price = service.price.toString()
            tags = service.tags.joinToString(", ")
            location = service.location
            existingImages = service.portfolioImages
        }
    }

    LaunchedEffect(serviceState.isSuccess) {
        if (serviceState.isSuccess) {
            viewModel.resetState()
            navController.popBackStack()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Service bearbeiten") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Zurück")
                    }
                }
            )
        }
    ) { paddingValues ->
        when {
            detailState.isLoading -> {
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
                        Text("Service wird geladen...")
                    }
                }
            }

            detailState.error != null -> {
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
                            horizontalAlignment = Alignment.CenterVertically as Alignment.Horizontal
                        ) {
                            Icon(
                                imageVector = Icons.Default.Error,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onErrorContainer
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = detailState.error!!,
                                color = MaterialTheme.colorScheme.onErrorContainer
                            )
                        }
                    }
                }
            }

            detailState.service != null -> {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues)
                        .padding(16.dp)
                        .verticalScroll(scrollState),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    if (detailState.provider != null) {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.primaryContainer
                            )
                        ) {
                            Row(
                                modifier = Modifier.padding(16.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = Modifier.size(60.dp),
                                    contentAlignment = Alignment.Center
                                ) {
                                    if (detailState.provider!!.profileImage.isNotEmpty()) {
                                        AsyncImage(
                                            model = ImageRequest.Builder(LocalContext.current)
                                                .data(detailState.provider!!.profileImage)
                                                .crossfade(true)
                                                .build(),
                                            contentDescription = "Profilbild",
                                            contentScale = ContentScale.Crop,
                                            modifier = Modifier
                                                .fillMaxSize()
                                                .clip(CircleShape)
                                                .background(MaterialTheme.colorScheme.primary)
                                        )
                                    } else {
                                        Box(
                                            modifier = Modifier
                                                .fillMaxSize()
                                                .clip(CircleShape)
                                                .background(MaterialTheme.colorScheme.primary),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Icon(
                                                imageVector = Icons.Default.Person,
                                                contentDescription = null,
                                                tint = MaterialTheme.colorScheme.onPrimary,
                                                modifier = Modifier.size(30.dp)
                                            )
                                        }
                                    }
                                }

                                Spacer(modifier = Modifier.width(12.dp))

                                Column {
                                    Text(
                                        text = detailState.provider!!.name,
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.onPrimaryContainer
                                    )
                                    Text(
                                        text = "Ihr Profilbild",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                                    )
                                }
                            }
                        }
                    }

                    Card(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Text(
                                text = "Service-Informationen",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )

                            TextField(
                                value = title,
                                onValueChange = { title = it },
                                label = { Text("Service-Titel") },
                                modifier = Modifier.fillMaxWidth(),
                                singleLine = true
                            )

                            TextField(
                                value = description,
                                onValueChange = { description = it },
                                label = { Text("Beschreibung") },
                                modifier = Modifier.fillMaxWidth(),
                                minLines = 3,
                                maxLines = 5
                            )

                            TextField(
                                value = price,
                                onValueChange = { price = it },
                                label = { Text("Preis (€)") },
                                modifier = Modifier.fillMaxWidth(),
                                singleLine = true
                            )

                            TextField(
                                value = tags,
                                onValueChange = { tags = it },
                                label = { Text("Tags (kommagetrennt)") },
                                placeholder = { Text("z.B. Webentwicklung, Mobile Apps, UI/UX") },
                                modifier = Modifier.fillMaxWidth()
                            )

                            TextField(
                                value = location,
                                onValueChange = { location = it },
                                label = { Text("Standort") },
                                modifier = Modifier.fillMaxWidth(),
                                singleLine = true
                            )
                        }
                    }

                    Card(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "Portfolio-Bilder",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )

                                OutlinedButton(
                                    onClick = { imagePickerLauncher.launch("image/*") },
                                    enabled = (existingImages.size + newImageUris.size) < 5
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Add,
                                        contentDescription = null,
                                        modifier = Modifier.size(16.dp)
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("Bilder hinzufügen")
                                }
                            }

                            Text(
                                text = "${existingImages.size + newImageUris.size}/5 Bilder",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.outline
                            )

                            if (existingImages.isNotEmpty()) {
                                Text(
                                    text = "Vorhandene Bilder",
                                    style = MaterialTheme.typography.labelMedium,
                                    fontWeight = FontWeight.Medium
                                )

                                LazyRow(
                                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    items(existingImages) { imageUrl ->
                                        ExistingServiceImageItem(
                                            imageUrl = imageUrl,
                                            onRemove = {
                                                viewModel.deleteServiceImage(imageUrl)
                                                existingImages = existingImages.filter { it != imageUrl }
                                            }
                                        )
                                    }
                                }
                            }

                            if (newImageUris.isNotEmpty()) {
                                Text(
                                    text = "Neue Bilder",
                                    style = MaterialTheme.typography.labelMedium,
                                    fontWeight = FontWeight.Medium
                                )

                                LazyRow(
                                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    items(newImageUris) { uri ->
                                        NewServiceImageItem(
                                            imageUri = uri,
                                            onRemove = {
                                                newImageUris = newImageUris.filter { it != uri }
                                            }
                                        )
                                    }
                                }
                            }

                            if (existingImages.isEmpty() && newImageUris.isEmpty()) {
                                Card(
                                    colors = CardDefaults.cardColors(
                                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                                    ),
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(120.dp)
                                ) {
                                    Box(
                                        modifier = Modifier.fillMaxSize(),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Column(
                                            horizontalAlignment = Alignment.CenterHorizontally
                                        ) {
                                            Icon(
                                                imageVector = Icons.Default.Image,
                                                contentDescription = null,
                                                modifier = Modifier.size(32.dp),
                                                tint = MaterialTheme.colorScheme.outline
                                            )
                                            Spacer(modifier = Modifier.height(8.dp))
                                            Text(
                                                text = "Keine Bilder vorhanden",
                                                style = MaterialTheme.typography.bodyMedium,
                                                color = MaterialTheme.colorScheme.outline
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    if (serviceState.isLoading) {
                        Box(
                            modifier = Modifier.fillMaxWidth(),
                            contentAlignment = Alignment.Center
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                CircularProgressIndicator(modifier = Modifier.size(20.dp))
                                Spacer(modifier = Modifier.width(12.dp))
                                Text("Änderungen werden gespeichert...")
                            }
                        }
                    } else {
                        Button(
                            onClick = {
                                val priceDouble = price.toDoubleOrNull() ?: 0.0
                                val tagList = tags.split(",").map { it.trim() }.filter { it.isNotEmpty() }
                                viewModel.updateService(
                                    serviceId = serviceId,
                                    title = title,
                                    description = description,
                                    price = priceDouble,
                                    tags = tagList,
                                    location = location,
                                    existingImages = existingImages,
                                    newImageUris = newImageUris
                                )
                            },
                            modifier = Modifier.fillMaxWidth(),
                            enabled = title.isNotEmpty() && description.isNotEmpty() &&
                                    price.isNotEmpty() && location.isNotEmpty()
                        ) {
                            Icon(
                                imageVector = Icons.Default.Save,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Änderungen speichern")
                        }
                    }

                    serviceState.error?.let {
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.errorContainer
                            )
                        ) {
                            Row(
                                modifier = Modifier.padding(16.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Error,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.onErrorContainer
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = it,
                                    color = MaterialTheme.colorScheme.onErrorContainer
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ExistingServiceImageItem(
    imageUrl: String,
    onRemove: () -> Unit
) {
    Box(
        modifier = Modifier.size(100.dp)
    ) {
        AsyncImage(
            model = ImageRequest.Builder(LocalContext.current)
                .data(imageUrl)
                .crossfade(true)
                .build(),
            contentDescription = "Service Bild",
            contentScale = ContentScale.Crop,
            modifier = Modifier
                .fillMaxSize()
                .clip(RoundedCornerShape(8.dp))
                .background(MaterialTheme.colorScheme.surfaceVariant)
        )

        IconButton(
            onClick = onRemove,
            modifier = Modifier
                .align(Alignment.TopEnd)
                .size(24.dp)
                .background(
                    MaterialTheme.colorScheme.error.copy(alpha = 0.9f),
                    RoundedCornerShape(12.dp)
                )
        ) {
            Icon(
                imageVector = Icons.Default.Delete,
                contentDescription = "Bild löschen",
                tint = MaterialTheme.colorScheme.onError,
                modifier = Modifier.size(16.dp)
            )
        }
    }
}

@Composable
private fun NewServiceImageItem(
    imageUri: Uri,
    onRemove: () -> Unit
) {
    Box(
        modifier = Modifier.size(100.dp)
    ) {
        AsyncImage(
            model = ImageRequest.Builder(LocalContext.current)
                .data(imageUri)
                .crossfade(true)
                .build(),
            contentDescription = "Neues Service Bild",
            contentScale = ContentScale.Crop,
            modifier = Modifier
                .fillMaxSize()
                .clip(RoundedCornerShape(8.dp))
                .background(MaterialTheme.colorScheme.surfaceVariant)
        )

        Surface(
            color = MaterialTheme.colorScheme.primary,
            shape = RoundedCornerShape(4.dp),
            modifier = Modifier
                .align(Alignment.TopStart)
                .padding(4.dp)
        ) {
            Text(
                text = "NEU",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onPrimary,
                modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp),
                fontWeight = FontWeight.Bold
            )
        }

        IconButton(
            onClick = onRemove,
            modifier = Modifier
                .align(Alignment.TopEnd)
                .size(24.dp)
                .background(
                    MaterialTheme.colorScheme.error.copy(alpha = 0.9f),
                    RoundedCornerShape(12.dp)
                )
        ) {
            Icon(
                imageVector = Icons.Default.Close,
                contentDescription = "Neues Bild entfernen",
                tint = MaterialTheme.colorScheme.onError,
                modifier = Modifier.size(16.dp)
            )
        }
    }
}