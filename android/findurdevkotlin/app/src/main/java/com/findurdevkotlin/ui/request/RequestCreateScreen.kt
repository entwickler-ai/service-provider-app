package com.findurdevkotlin.ui.request

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.AutoFixHigh
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
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
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.findurdevkotlin.ui.service.ServiceViewModel
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RequestCreateScreen(
    navController: NavController,
    serviceId: String,
    serviceTitle: String,
    providerId: String,
    providerName: String,
    viewModel: RequestViewModel = hiltViewModel()
) {
    var title by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var budget by remember { mutableStateOf("") }
    var timeline by remember { mutableStateOf("") }
    var requirements by remember { mutableStateOf("") }
    var showImproveDialog by remember { mutableStateOf(false) }
    var improvedText by remember { mutableStateOf<String?>(null) }
    var isImproving by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    val requestState by viewModel.requestState.collectAsState()
    val scrollState = rememberScrollState()

    val serviceViewModel: ServiceViewModel = hiltViewModel()
    LaunchedEffect(serviceId) {
        serviceViewModel.getServiceById(serviceId)
    }
    val serviceState by serviceViewModel.serviceDetailState.collectAsState()
    val actualProviderName = serviceState.service?.providerName ?: providerName

    LaunchedEffect(requestState.isSuccess) {
        if (requestState.isSuccess) {
            navController.popBackStack()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Anfrage erstellen") },
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
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
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
                        text = "Service",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                    Text(
                        text = serviceTitle,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                    Text(
                        text = "von $actualProviderName",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
            }

            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(
                        text = "Projektdetails",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )

                    TextField(
                        value = title,
                        onValueChange = { title = it },
                        label = { Text("Projekttitel") },
                        placeholder = { Text("z.B. E-Commerce Website für Schmuck") },
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
                            label = { Text("Projektbeschreibung") },
                            placeholder = { Text("Beschreiben Sie Ihr Projekt im Detail...") },
                            modifier = Modifier.weight(1f),
                            minLines = 4,
                            maxLines = 8,
                            enabled = !isImproving
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        IconButton(
                            onClick = {
                                if (description.trim().isNotEmpty()) {
                                    isImproving = true
                                    scope.launch {
                                        improvedText = viewModel.openAIService.improveText(description, "Projektbeschreibung")
                                        isImproving = false
                                        if (improvedText != null) {
                                            showImproveDialog = true
                                        } else {
                                            //
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

                    TextField(
                        value = requirements,
                        onValueChange = { requirements = it },
                        label = { Text("Spezielle Anforderungen") },
                        placeholder = { Text("z.B. Mobile-optimiert, Payment-Integration, etc.") },
                        modifier = Modifier.fillMaxWidth(),
                        minLines = 2,
                        maxLines = 4
                    )
                }
            }

            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(
                        text = "Budget & Zeitrahmen",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )

                    TextField(
                        value = budget,
                        onValueChange = { budget = it },
                        label = { Text("Budget (€)") },
                        placeholder = { Text("z.B. 1500") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true
                    )

                    var expanded by remember { mutableStateOf(false) }
                    val timelineOptions = listOf(
                        "1-2 Wochen",
                        "3-4 Wochen",
                        "1-2 Monate",
                        "2-3 Monate",
                        "3-6 Monate",
                        "Flexibel"
                    )

                    ExposedDropdownMenuBox(
                        expanded = expanded,
                        onExpandedChange = { expanded = !expanded }
                    ) {
                        TextField(
                            value = timeline,
                            onValueChange = { },
                            readOnly = true,
                            label = { Text("Zeitrahmen") },
                            trailingIcon = {
                                ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded)
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .menuAnchor()
                        )

                        ExposedDropdownMenu(
                            expanded = expanded,
                            onDismissRequest = { expanded = false }
                        ) {
                            timelineOptions.forEach { option ->
                                DropdownMenuItem(
                                    text = { Text(option) },
                                    onClick = {
                                        timeline = option
                                        expanded = false
                                    }
                                )
                            }
                        }
                    }
                }
            }

            if (requestState.isLoading || isImproving) {
                Box(
                    modifier = Modifier.fillMaxWidth(),
                    contentAlignment = Alignment.Center
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        CircularProgressIndicator(modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(if (requestState.isLoading) "Anfrage wird erstellt..." else "Beschreibung wird optimiert...")
                    }
                }
            } else {
                Button(
                    onClick = {
                        val budgetValue = budget.toDoubleOrNull() ?: 0.0
                        val requirementsList = requirements.split("\n")
                            .map { it.trim() }
                            .filter { it.isNotEmpty() }

                        viewModel.createRequest(
                            serviceId = serviceId,
                            serviceTitle = serviceTitle,
                            providerId = providerId,
                            providerName = actualProviderName,
                            title = title,
                            description = description,
                            budget = budgetValue,
                            timeline = timeline,
                            requirements = requirementsList
                        )
                    },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = title.isNotEmpty() && description.isNotEmpty() &&
                            budget.isNotEmpty() && timeline.isNotEmpty() && !isImproving
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.Send,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Anfrage senden")
                }
            }

            requestState.error?.let { error ->
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
                            text = error,
                            color = MaterialTheme.colorScheme.onErrorContainer
                        )
                    }
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
                            text = "Was passiert als nächstes?",
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Der Dienstleister erhält Ihre Anfrage und kann sie annehmen oder ablehnen. Bei Annahme können Sie direkt per Chat kommunizieren.",
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