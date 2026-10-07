package com.findurdevkotlin.ui.service

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.findurdevkotlin.ui.navigation.Screen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ServiceListScreen(
    navController: NavController,
    viewModel: ServiceViewModel = hiltViewModel(),
    initialCategory: String? = null
) {
    val state by viewModel.serviceState.collectAsState()

    var searchQuery by remember { mutableStateOf("") }
    var selectedLocation by remember { mutableStateOf("") }
    var selectedCategory by remember { mutableStateOf("") }
    var minPrice by remember { mutableStateOf("") }
    var maxPrice by remember { mutableStateOf("") }
    var showFilters by remember { mutableStateOf(false) }
    var sortOrder by remember { mutableStateOf("newest") }
    var filtersApplied by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.getServices()
    }

    LaunchedEffect(initialCategory) {
        if (initialCategory != null) {
            selectedCategory = initialCategory
        }
    }

    val filteredServices = remember(state.services, searchQuery) {
        if (searchQuery.isNotEmpty() && !filtersApplied) {
            state.services.filter { service ->
                service.title.contains(searchQuery, ignoreCase = true) ||
                        service.description.contains(searchQuery, ignoreCase = true) ||
                        service.location.contains(searchQuery, ignoreCase = true) ||
                        service.tags.any { tag -> tag.contains(searchQuery, ignoreCase = true) }
            }
        } else {
            state.services
        }
    }

    LaunchedEffect(searchQuery) {
        if (filtersApplied) {
            viewModel.searchServices(
                query = searchQuery,
                location = selectedLocation,
                category = selectedCategory,
                minPrice = minPrice.toDoubleOrNull(),
                maxPrice = maxPrice.toDoubleOrNull(),
                sortOrder = sortOrder
            )
        }
    }

    LaunchedEffect(selectedLocation, selectedCategory, minPrice, maxPrice, sortOrder) {
        if (filtersApplied) {
            viewModel.searchServices(
                query = searchQuery,
                location = selectedLocation,
                category = selectedCategory,
                minPrice = minPrice.toDoubleOrNull(),
                maxPrice = maxPrice.toDoubleOrNull(),
                sortOrder = sortOrder
            )
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text("Dienstleistungen")
                },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Zurück")
                    }
                },
                actions = {
                    IconButton(onClick = { showFilters = !showFilters }) {
                        Icon(
                            Icons.Default.FilterList,
                            contentDescription = "Filter",
                            tint = if (showFilters || selectedLocation.isNotEmpty() ||
                                selectedCategory.isNotEmpty() || minPrice.isNotEmpty() ||
                                maxPrice.isNotEmpty() || sortOrder != "newest") {
                                MaterialTheme.colorScheme.primary
                            } else {
                                MaterialTheme.colorScheme.onSurface
                            }
                        )
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
            SearchSection(
                searchQuery = searchQuery,
                onSearchChange = { searchQuery = it },
                modifier = Modifier.padding(16.dp)
            )

            if (showFilters) {
                FilterSection(
                    selectedLocation = selectedLocation,
                    onLocationChange = {
                        selectedLocation = it
                        filtersApplied = true
                    },
                    selectedCategory = selectedCategory,
                    onCategoryChange = {
                        selectedCategory = it
                        filtersApplied = true
                    },
                    minPrice = minPrice,
                    onMinPriceChange = {
                        minPrice = it
                        filtersApplied = true
                    },
                    maxPrice = maxPrice,
                    onMaxPriceChange = {
                        maxPrice = it
                        filtersApplied = true
                    },
                    sortOrder = sortOrder,
                    onSortOrderChange = {
                        sortOrder = it
                        filtersApplied = true
                    },
                    onClearFilters = {
                        selectedLocation = ""
                        selectedCategory = ""
                        minPrice = ""
                        maxPrice = ""
                        searchQuery = ""
                        sortOrder = "newest"
                        filtersApplied = false
                        viewModel.getServices()
                    },
                    modifier = Modifier.padding(horizontal = 16.dp)
                )

                Spacer(modifier = Modifier.height(8.dp))
            }

            when {
                state.isLoading -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            CircularProgressIndicator()
                            Spacer(modifier = Modifier.height(8.dp))
                            Text("Services werden geladen...")
                        }
                    }
                }

                state.error != null -> {
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
                                    text = state.error!!,
                                    color = MaterialTheme.colorScheme.onErrorContainer
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                TextButton(
                                    onClick = { viewModel.getServices() }
                                ) {
                                    Text("Erneut versuchen")
                                }
                            }
                        }
                    }
                }

                (state.services.isEmpty() && searchQuery.isEmpty()) ||
                        (filteredServices.isEmpty() && searchQuery.isNotEmpty()) -> {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(16.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Card {
                            Column(
                                modifier = Modifier.padding(24.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Icon(
                                    imageVector = Icons.Default.SearchOff,
                                    contentDescription = null,
                                    modifier = Modifier.size(48.dp),
                                    tint = MaterialTheme.colorScheme.outline
                                )
                                Spacer(modifier = Modifier.height(16.dp))
                                Text(
                                    text = "Keine Services gefunden",
                                    style = MaterialTheme.typography.titleMedium
                                )
                                Text(
                                    text = "Versuchen Sie andere Suchbegriffe oder Filter.",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.outline
                                )
                                Spacer(modifier = Modifier.height(16.dp))
                                OutlinedButton(
                                    onClick = {
                                        if (filtersApplied) {
                                            selectedLocation = ""
                                            selectedCategory = ""
                                            minPrice = ""
                                            maxPrice = ""
                                            sortOrder = "newest"
                                            filtersApplied = false
                                            if (searchQuery.isNotEmpty()) {
                                                viewModel.searchServices(
                                                    query = searchQuery,
                                                    location = "",
                                                    category = "",
                                                    minPrice = null,
                                                    maxPrice = null,
                                                    sortOrder = "newest"
                                                )
                                            } else {
                                                viewModel.getServices()
                                            }
                                        } else {
                                            searchQuery = ""
                                        }
                                    }
                                ) {
                                    Text("Filter zurücksetzen")
                                }
                            }
                        }
                    }
                }

                else -> {
                    LazyColumn(
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        item {
                            Text(
                                text = "${filteredServices.size} Services gefunden",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.outline,
                                modifier = Modifier.padding(bottom = 8.dp)
                            )
                        }

                        items(filteredServices) { service ->
                            ServiceCard(
                                service = service,
                                onClick = {
                                    navController.navigate(Screen.ServiceDetail.createRoute(service.id))
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SearchSection(
    searchQuery: String,
    onSearchChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    TextField(
        value = searchQuery,
        onValueChange = onSearchChange,
        modifier = modifier.fillMaxWidth(),
        placeholder = { Text("Services suchen...") },
        leadingIcon = {
            Icon(Icons.Default.Search, contentDescription = null)
        },
        trailingIcon = {
            if (searchQuery.isNotEmpty()) {
                IconButton(onClick = { onSearchChange("") }) {
                    Icon(Icons.Default.Clear, contentDescription = "Löschen")
                }
            }
        },
        singleLine = true,
        shape = RoundedCornerShape(12.dp),
        colors = TextFieldDefaults.colors(
            focusedIndicatorColor = Color.Transparent,
            unfocusedIndicatorColor = Color.Transparent
        )
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FilterSection(
    selectedLocation: String,
    onLocationChange: (String) -> Unit,
    selectedCategory: String,
    onCategoryChange: (String) -> Unit,
    minPrice: String,
    onMinPriceChange: (String) -> Unit,
    maxPrice: String,
    onMaxPriceChange: (String) -> Unit,
    sortOrder: String,
    onSortOrderChange: (String) -> Unit,
    onClearFilters: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth()
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
                    text = "Filter",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                TextButton(onClick = onClearFilters) {
                    Text("Zurücksetzen")
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            val categories = listOf(
                "", "Webentwicklung", "Mobile Apps", "Design",
                "Marketing", "Beratung", "Fotografie", "Sonstige"
            )

            var categoryExpanded by remember { mutableStateOf(false) }

            ExposedDropdownMenuBox(
                expanded = categoryExpanded,
                onExpandedChange = { categoryExpanded = !categoryExpanded }
            ) {
                TextField(
                    value = if (selectedCategory.isEmpty() || selectedCategory == "{category}") "Auswählen" else selectedCategory,
                    onValueChange = { },
                    readOnly = true,
                    label = { Text("Kategorie") },
                    trailingIcon = {
                        ExposedDropdownMenuDefaults.TrailingIcon(expanded = categoryExpanded)
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                    colors = ExposedDropdownMenuDefaults.textFieldColors()
                )

                ExposedDropdownMenu(
                    expanded = categoryExpanded,
                    onDismissRequest = { categoryExpanded = false }
                ) {
                    categories.forEach { category ->
                        DropdownMenuItem(
                            text = {
                                Text(category.ifEmpty { "Auswählen" })
                            },
                            onClick = {
                                onCategoryChange(category)
                                categoryExpanded = false
                            }
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            TextField(
                value = selectedLocation,
                onValueChange = onLocationChange,
                label = { Text("Standort") },
                placeholder = { Text("z.B. Berlin, München...") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                TextField(
                    value = minPrice,
                    onValueChange = onMinPriceChange,
                    label = { Text("Min Preis") },
                    placeholder = { Text("€") },
                    modifier = Modifier.weight(1f),
                    singleLine = true
                )

                TextField(
                    value = maxPrice,
                    onValueChange = onMaxPriceChange,
                    label = { Text("Max Preis") },
                    placeholder = { Text("€") },
                    modifier = Modifier.weight(1f),
                    singleLine = true
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            val sortOptions = listOf(
                "newest" to "Neueste zuerst",
                "oldest" to "Älteste zuerst",
                "price_low" to "Preis niedrig-hoch",
                "price_high" to "Preis hoch-niedrig",
                "rating" to "Beste Bewertung"
            )

            var sortExpanded by remember { mutableStateOf(false) }

            ExposedDropdownMenuBox(
                expanded = sortExpanded,
                onExpandedChange = { sortExpanded = !sortExpanded }
            ) {
                TextField(
                    value = sortOptions.find { it.first == sortOrder }?.second ?: "Neueste zuerst",
                    onValueChange = { },
                    readOnly = true,
                    label = { Text("Sortierung") },
                    trailingIcon = {
                        ExposedDropdownMenuDefaults.TrailingIcon(expanded = sortExpanded)
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                    colors = ExposedDropdownMenuDefaults.textFieldColors()
                )

                ExposedDropdownMenu(
                    expanded = sortExpanded,
                    onDismissRequest = { sortExpanded = false }
                ) {
                    sortOptions.forEach { (key, label) ->
                        DropdownMenuItem(
                            text = { Text(label) },
                            onClick = {
                                onSortOrderChange(key)
                                sortExpanded = false
                            }
                        )
                    }
                }
            }
        }
    }
}