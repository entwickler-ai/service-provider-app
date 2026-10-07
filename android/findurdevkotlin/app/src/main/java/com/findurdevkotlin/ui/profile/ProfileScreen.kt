package com.findurdevkotlin.ui.profile

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
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Save
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Work
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import coil.compose.AsyncImage
import coil.request.ImageRequest

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    navController: NavController,
    viewModel: ProfileViewModel = hiltViewModel()
) {
    val profileState by viewModel.profileState.collectAsState()
    val scrollState = rememberScrollState()
    LocalContext.current

    var name by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var location by remember { mutableStateOf("") }
    var role by remember { mutableStateOf("") }
    var profileImageUrl by remember { mutableStateOf("") }

    var showImageDialog by remember { mutableStateOf(false) }

    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let { viewModel.uploadProfileImage(it) }
    }

    LaunchedEffect(Unit) {
        viewModel.loadUserProfile()
    }

    LaunchedEffect(profileState.user) {
        profileState.user?.let { user ->
            name = user.name
            email = user.email
            description = user.description
            location = user.location
            role = user.role
            profileImageUrl = user.profileImage
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Mein Profil") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Zurück")
                    }
                },
                actions = {
                    if (profileState.isSuccess) {
                        IconButton(onClick = {
                            viewModel.resetState()
                            navController.popBackStack()
                        }) {
                            Icon(Icons.Default.Check, contentDescription = "Fertig")
                        }
                    }
                }
            )
        }
    ) { paddingValues ->
        when {
            profileState.isLoading -> {
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
                        Text("Profil wird geladen...")
                    }
                }
            }

            profileState.error != null -> {
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
                                text = profileState.error!!,
                                color = MaterialTheme.colorScheme.onErrorContainer
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            TextButton(
                                onClick = { viewModel.loadUserProfile() }
                            ) {
                                Text("Erneut versuchen")
                            }
                        }
                    }
                }
            }

            else -> {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues)
                        .padding(16.dp)
                        .verticalScroll(scrollState),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    ProfileHeaderCard(
                        name = name,
                        email = email,
                        role = role,
                        profileImageUrl = profileImageUrl,
                        isUploadingImage = profileState.isUploadingImage,
                        onImageClick = { showImageDialog = true }
                    )

                    Card(
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Text(
                                text = "Persönliche Informationen",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )

                            TextField(
                                value = name,
                                onValueChange = { name = it },
                                label = { Text("Name") },
                                modifier = Modifier.fillMaxWidth(),
                                singleLine = true,
                                leadingIcon = {
                                    Icon(Icons.Default.Person, contentDescription = null)
                                }
                            )

                            TextField(
                                value = email,
                                onValueChange = { },
                                label = { Text("E-Mail") },
                                modifier = Modifier.fillMaxWidth(),
                                singleLine = true,
                                enabled = false,
                                leadingIcon = {
                                    Icon(Icons.Default.Email, contentDescription = null)
                                }
                            )

                            TextField(
                                value = location,
                                onValueChange = { location = it },
                                label = { Text("Standort") },
                                placeholder = { Text("z.B. Berlin, Deutschland") },
                                modifier = Modifier.fillMaxWidth(),
                                singleLine = true,
                                leadingIcon = {
                                    Icon(Icons.Default.LocationOn, contentDescription = null)
                                }
                            )

                            TextField(
                                value = description,
                                onValueChange = { description = it },
                                label = {
                                    Text(if (role == "provider") "Über mich / Services" else "Über mich")
                                },
                                placeholder = {
                                    Text(
                                        if (role == "provider")
                                            "Beschreiben Sie Ihre Fähigkeiten und Dienstleistungen..."
                                        else
                                            "Erzählen Sie etwas über sich..."
                                    )
                                },
                                modifier = Modifier.fillMaxWidth(),
                                minLines = 3,
                                maxLines = 6,
                                leadingIcon = {
                                    Icon(Icons.Default.Description, contentDescription = null)
                                }
                            )
                        }
                    }

                    if (role == "provider") {
                        ProviderStatsCard(viewModel = viewModel)
                    }

                    if (profileState.isUpdating) {
                        Card(
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                CircularProgressIndicator(
                                    modifier = Modifier.size(20.dp),
                                    strokeWidth = 2.dp
                                )
                                Spacer(modifier = Modifier.width(12.dp))
                                Text("Profil wird gespeichert...")
                            }
                        }
                    } else {
                        Button(
                            onClick = {
                                viewModel.updateUserProfile(
                                    name = name,
                                    description = description,
                                    location = location
                                )
                            },
                            modifier = Modifier.fillMaxWidth(),
                            enabled = name.isNotEmpty()
                        ) {
                            Icon(
                                imageVector = Icons.Default.Save,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Profil speichern")
                        }
                    }

                    if (profileState.isSuccess) {
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.primaryContainer
                            )
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = Icons.Default.CheckCircle,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                                Spacer(modifier = Modifier.width(12.dp))
                                Text(
                                    text = "Profil erfolgreich gespeichert!",
                                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                                    fontWeight = FontWeight.Medium
                                )
                            }
                        }
                    }
                }
            }
        }

        if (showImageDialog) {
            ProfileImageDialog(
                onSelectImage = {
                    imagePickerLauncher.launch("image/*")
                    showImageDialog = false
                },
                onDeleteImage = {
                    viewModel.deleteProfileImage()
                    showImageDialog = false
                },
                onDismiss = { showImageDialog = false },
                hasImage = profileImageUrl.isNotEmpty()
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ProfileHeaderCard(
    name: String,
    email: String,
    role: String,
    profileImageUrl: String,
    isUploadingImage: Boolean,
    onImageClick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier.size(120.dp),
                contentAlignment = Alignment.Center
            ) {
                if (profileImageUrl.isNotEmpty()) {
                    AsyncImage(
                        model = ImageRequest.Builder(LocalContext.current)
                            .data(profileImageUrl)
                            .crossfade(true)
                            .build(),
                        contentDescription = "Profilbild",
                        contentScale = ContentScale.Crop,
                        modifier = Modifier
                            .size(120.dp)
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.primary)
                    )
                } else {
                    Box(
                        modifier = Modifier
                            .size(120.dp)
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.primary),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Person,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onPrimary,
                            modifier = Modifier.size(60.dp)
                        )
                    }
                }

                if (isUploadingImage) {
                    Box(
                        modifier = Modifier
                            .size(120.dp)
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.8f)),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(32.dp),
                            strokeWidth = 3.dp
                        )
                    }
                } else {
                    Card(
                        onClick = onImageClick,
                        modifier = Modifier
                            .size(32.dp)
                            .offset(x = 42.dp, y = 42.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.secondary
                        ),
                        shape = CircleShape
                    ) {
                        Box(
                            contentAlignment = Alignment.Center,
                            modifier = Modifier.fillMaxSize()
                        ) {
                            Icon(
                                imageVector = Icons.Default.Edit,
                                contentDescription = "Profilbild bearbeiten",
                                tint = MaterialTheme.colorScheme.onSecondary,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = name.ifEmpty { "Kein Name" },
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = email,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onPrimaryContainer,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(12.dp))

            Surface(
                color = MaterialTheme.colorScheme.secondary,
                shape = androidx.compose.foundation.shape.RoundedCornerShape(16.dp)
            ) {
                Text(
                    text = when(role) {
                        "provider" -> "Dienstleister"
                        "customer" -> "Kunde"
                        else -> "Benutzer"
                    },
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSecondary,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }
        }
    }
}

@Composable
private fun ProfileImageDialog(
    onSelectImage: () -> Unit,
    onDeleteImage: () -> Unit,
    onDismiss: () -> Unit,
    hasImage: Boolean
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Profilbild") },
        text = {
            Column {
                if (hasImage) {
                    Text("Was möchten Sie mit Ihrem Profilbild machen?")
                } else {
                    Text("Möchten Sie ein Profilbild hinzufügen?")
                }
            }
        },
        confirmButton = {
            Row {
                TextButton(onClick = onSelectImage) {
                    Text(if (hasImage) "Ändern" else "Hinzufügen")
                }
                if (hasImage) {
                    Spacer(modifier = Modifier.width(8.dp))
                    TextButton(
                        onClick = onDeleteImage,
                        colors = ButtonDefaults.textButtonColors(
                            contentColor = MaterialTheme.colorScheme.error
                        )
                    ) {
                        Text("Löschen")
                    }
                }
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
private fun ProviderStatsCard(viewModel: ProfileViewModel) {
    val statsState by viewModel.statsState.collectAsState()

    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Statistiken",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )

                if (statsState.isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            if (statsState.error != null) {
                Text(
                    text = "Fehler beim Laden der Statistiken",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error
                )
            } else {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    StatItem(
                        icon = Icons.Default.Work,
                        label = "Services",
                        value = statsState.servicesCount.toString()
                    )
                    StatItem(
                        icon = Icons.Default.Star,
                        label = "Bewertung",
                        value = if (statsState.averageRating > 0.0) {
                            String.format("%.1f", statsState.averageRating)
                        } else {
                            "0"
                        }
                    )
                    StatItem(
                        icon = Icons.Default.People,
                        label = "Aktive Kunden",
                        value = statsState.activeRequestsCount.toString()
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun StatItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String,
    onClick: (() -> Unit)? = null
) {
    if (onClick != null) {
        Card(
            onClick = onClick,
            modifier = Modifier.padding(4.dp)
        ) {
            StatItemContent(icon, label, value)
        }
    } else {
        StatItemContent(icon, label, value)
    }
}

@Composable
private fun StatItemContent(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.padding(8.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = value,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.outline
        )
    }
}