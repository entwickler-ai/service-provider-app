package com.findurdevkotlin.ui.service

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AutoFixHigh
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Save
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
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
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ServiceCreateScreen(
    navController: NavController,
    viewModel: ServiceViewModel = hiltViewModel()
) {
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var price by remember { mutableStateOf("") }
    var tags by remember { mutableStateOf("") }
    var location by remember { mutableStateOf("") }
    var selectedImageUris by remember { mutableStateOf<List<Uri>>(emptyList()) }
    var showImproveDialog by remember { mutableStateOf(false) }
    var improvedText by remember { mutableStateOf<String?>(null) }
    var isImproving by remember { mutableStateOf(false) }

    var priceError by remember { mutableStateOf("") }
    var isValidPrice by remember { mutableStateOf(true) }

    val scope = rememberCoroutineScope()
    val state by viewModel.serviceState.collectAsState()
    val scrollState = rememberScrollState()

    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetMultipleContents()
    ) { uris ->
        if (uris.isNotEmpty()) {
            val currentImages = selectedImageUris.toMutableList()
            val newImages = uris.take(5 - currentImages.size)
            currentImages.addAll(newImages)
            selectedImageUris = currentImages
        }
    }

    fun validatePrice(priceText: String) {
        if (priceText.isEmpty()) {
            priceError = ""
            isValidPrice = true
            return
        }

        val allowedPattern = Regex("^[0-9.,]*$")
        if (!allowedPattern.matches(priceText)) {
            priceError = "Nur Zahlen und Komma/Punkt erlaubt"
            isValidPrice = false
            return
        }

        val commaCount = priceText.count { it == ',' }
        val dotCount = priceText.count { it == '.' }
        if (commaCount > 1 || dotCount > 1 || (commaCount > 0 && dotCount > 0)) {
            priceError = "Ungültiges Format"
            isValidPrice = false
            return
        }

        val normalizedPrice = priceText.replace(",", ".")
        val priceValue = normalizedPrice.toDoubleOrNull()

        if (priceValue != null && priceValue > 0) {
            priceError = ""
            isValidPrice = true
        } else {
            priceError = "Bitte geben Sie einen gültigen Preis ein"
            isValidPrice = false
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Neuen Service erstellen") },
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
                .padding(16.dp)
                .verticalScroll(scrollState),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
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
                        placeholder = { Text("z.B. Mobile App Entwicklung") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        TextField(
                            value = description,
                            onValueChange = { description = it },
                            label = { Text("Beschreibung") },
                            placeholder = { Text("Beschreiben Sie Ihren Service im Detail...") },
                            modifier = Modifier.weight(1f),
                            minLines = 3,
                            maxLines = 5,
                            enabled = !isImproving
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        IconButton(
                            onClick = {
                                if (description.trim().isNotEmpty()) {
                                    isImproving = true
                                    scope.launch {
                                        improvedText = viewModel.openAIService.improveText(description, "Service-Beschreibung")
                                        isImproving = false
                                        if (improvedText != null) {
                                            showImproveDialog = true
                                        }
                                    }
                                }
                            },
                            enabled = description.trim().isNotEmpty() && !isImproving
                        ) {
                            Icon(
                                imageVector = Icons.Default.AutoFixHigh,
                                contentDescription = "Beschreibung optimieren",
                                tint = if (description.trim().isNotEmpty() && !isImproving) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline
                            )
                        }
                    }

                    Column {
                        TextField(
                            value = price,
                            onValueChange = { newValue ->
                                price = newValue
                                validatePrice(newValue)
                            },
                            label = { Text("Preis (€)") },
                            placeholder = { Text("z.B. 500") },
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                            isError = !isValidPrice,
                            colors = TextFieldDefaults.colors(
                                focusedIndicatorColor = if (isValidPrice) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.error,
                                unfocusedIndicatorColor = if (isValidPrice) MaterialTheme.colorScheme.outline else MaterialTheme.colorScheme.error,
                                errorIndicatorColor = MaterialTheme.colorScheme.error
                            )
                        )

                        if (priceError.isNotEmpty()) {
                            Text(
                                text = priceError,
                                color = MaterialTheme.colorScheme.error,
                                style = MaterialTheme.typography.bodySmall,
                                modifier = Modifier.padding(start = 16.dp, top = 4.dp)
                            )
                        }
                    }

                    TextField(
                        value = tags,
                        onValueChange = { tags = it },
                        label = { Text("Tags") },
                        placeholder = { Text("z.B. React, Mobile Apps, iOS, Android") },
                        modifier = Modifier.fillMaxWidth()
                    )

                    TextField(
                        value = location,
                        onValueChange = { location = it },
                        label = { Text("Standort") },
                        placeholder = { Text("z.B. Hamburg, Deutschland") },
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
                            enabled = selectedImageUris.size < 5
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
                        text = "${selectedImageUris.size}/5 Bilder ausgewählt",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.outline
                    )

                    if (selectedImageUris.isNotEmpty()) {
                        LazyRow(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            items(selectedImageUris) { uri ->
                                ServiceImageItem(
                                    imageUri = uri,
                                    onRemove = {
                                        selectedImageUris = selectedImageUris.filter { it != uri }
                                    }
                                )
                            }
                        }
                    } else {
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
                                        text = "Noch keine Bilder hinzugefügt",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.outline
                                    )
                                }
                            }
                        }
                    }
                }
            }

            Spacer(Modifier.height(8.dp))

            if (state.isLoading || isImproving) {
                Box(
                    modifier = Modifier.fillMaxWidth(),
                    contentAlignment = Alignment.Center
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        CircularProgressIndicator(modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(if (state.isLoading) "Service wird erstellt..." else "Beschreibung wird optimiert...")
                    }
                }
            } else {
                Button(
                    onClick = {
                        val priceDouble = price.replace(",", ".").toDoubleOrNull() ?: 0.0
                        val tagList = tags.split(",").map { it.trim() }.filter { it.isNotEmpty() }
                        viewModel.createService(
                            title = title,
                            description = description,
                            price = priceDouble,
                            tags = tagList,
                            location = location,
                            imageUris = selectedImageUris
                        )
                    },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = title.isNotEmpty() && description.isNotEmpty() &&
                            price.isNotEmpty() && location.isNotEmpty() && !isImproving && isValidPrice
                ) {
                    Icon(
                        imageVector = Icons.Default.Save,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Service erstellen")
                }
            }

            state.error?.let {
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

            if (state.isSuccess) {
                Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.primaryContainer
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Service erfolgreich erstellt!",
                            color = MaterialTheme.colorScheme.onPrimaryContainer,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }

                LaunchedEffect(Unit) {
                    kotlinx.coroutines.delay(1500)
                    navController.popBackStack()
                }
            }

            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.Top
                ) {
                    Icon(
                        imageVector = Icons.Default.Info,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Column {
                        Text(
                            text = "Tipps für einen erfolgreichen Service",
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "• Verwenden Sie aussagekräftige Bilder\n• Beschreiben Sie Ihren Service detailliert\n• Setzen Sie einen fairen Preis\n• Nutzen Sie relevante Tags",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }

    if (showImproveDialog && improvedText != null) {
        AlertDialog(
            onDismissRequest = { showImproveDialog = false },
            title = { Text("Optimierte Beschreibung") },
            text = { Text(improvedText!!) },
            confirmButton = {
                TextButton(onClick = {
                    description = improvedText!!
                    showImproveDialog = false
                }) { Text("Annehmen") }
            },
            dismissButton = {
                TextButton(onClick = { showImproveDialog = false }) { Text("Ablehnen") }
            }
        )
    }
}

@Composable
private fun ServiceImageItem(
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
                imageVector = Icons.Default.Close,
                contentDescription = "Bild entfernen",
                tint = MaterialTheme.colorScheme.onError,
                modifier = Modifier.size(16.dp)
            )
        }
    }
}