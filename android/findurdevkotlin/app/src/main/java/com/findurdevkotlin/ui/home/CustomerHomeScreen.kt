package com.findurdevkotlin.ui.home

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.findurdevkotlin.ui.auth.AuthViewModel
import com.findurdevkotlin.ui.navigation.Screen
import com.findurdevkotlin.ui.service.ServiceCard
import com.findurdevkotlin.ui.service.ServiceViewModel
import com.findurdevkotlin.ui.chat.ChatViewModel
import com.findurdevkotlin.ui.request.RequestViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CustomerHomeScreen(
    navController: NavController,
    authViewModel: AuthViewModel = hiltViewModel(),
    serviceViewModel: ServiceViewModel = hiltViewModel(),
    chatViewModel: ChatViewModel = hiltViewModel(),
    requestViewModel: RequestViewModel = hiltViewModel()
) {
    val serviceState by serviceViewModel.serviceState.collectAsState()
    val totalUnreadCount by chatViewModel.totalUnreadCount.collectAsState()
    val currentUser by authViewModel.currentUser.collectAsState()

    val acceptedRequestsCount by requestViewModel.newAcceptedRequestsCount.collectAsState()
    val rejectedRequestsCount by requestViewModel.newRejectedRequestsCount.collectAsState()
    val completedRequestsCount by requestViewModel.newCompletedRequestsCount.collectAsState()

    val totalRequestUpdates = acceptedRequestsCount + rejectedRequestsCount + completedRequestsCount

    LaunchedEffect(Unit) {
        serviceViewModel.getServices()
        requestViewModel.loadRequestUpdatesCount()
        authViewModel.loadCurrentUser()
    }

    Scaffold { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(9.dp),
            verticalArrangement = Arrangement.spacedBy(3.dp)
        ) {
            item {
                Column {
                    Text(
                        text = "Kunde Dashboard",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Hallo,",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = currentUser?.name ?: "",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
            }

            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    BadgedBox(
                        badge = {
                            if (totalRequestUpdates > 0) {
                                Badge {
                                    Text(
                                        text = if (totalRequestUpdates > 99) "99+" else totalRequestUpdates.toString()
                                    )
                                }
                            }
                        }
                    ) {
                        IconButton(onClick = {
                            requestViewModel.markRequestUpdatesAsRead()
                            navController.navigate(Screen.RequestList.createRoute(isProvider = false))
                        }) {
                            Icon(Icons.Default.RequestQuote, contentDescription = "Anfragen")
                        }
                    }

                    BadgedBox(
                        badge = {
                            if (totalUnreadCount > 0) {
                                Badge {
                                    Text(
                                        text = if (totalUnreadCount > 99) "99+" else totalUnreadCount.toString()
                                    )
                                }
                            }
                        }
                    ) {
                        IconButton(onClick = {
                            navController.navigate(Screen.ChatList.route)
                        }) {
                            Icon(Icons.AutoMirrored.Filled.Chat, contentDescription = "Nachrichten")
                        }
                    }

                    IconButton(onClick = {
                        navController.navigate(Screen.Profile.route)
                    }) {
                        Icon(Icons.Default.Person, contentDescription = "Profil")
                    }

                    IconButton(onClick = {
                        authViewModel.logout()
                        navController.navigate(Screen.Login.route) {
                            popUpTo(navController.graph.startDestinationId) { inclusive = true }
                        }
                    }) {
                        Icon(Icons.AutoMirrored.Filled.ExitToApp, contentDescription = "Abmelden")
                    }
                }
            }

            item {
                WelcomeCustomerHeader(
                    totalRequestUpdates = totalRequestUpdates,
                    acceptedCount = acceptedRequestsCount,
                    rejectedCount = rejectedRequestsCount,
                    completedCount = completedRequestsCount,
                    unreadMessagesCount = totalUnreadCount
                )
            }

            item {
                SearchBar(onSearchClick = {
                    navController.navigate(Screen.ServiceList.route)
                })
            }

            item {
                PopularCategoriesCard(navController = navController)
            }

            item {
                QuickActionsCustomerCard(
                    navController = navController,
                    requestUpdatesCount = totalRequestUpdates,
                    unreadMessagesCount = totalUnreadCount
                )
            }

            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Aktuelle Services",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                    TextButton(
                        onClick = { navController.navigate(Screen.ServiceList.route) }
                    ) {
                        Text("Alle anzeigen")
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
            }

            item {
                when {
                    serviceState.isLoading -> {
                        Box(
                            modifier = Modifier.fillMaxWidth(),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator()
                        }
                    }

                    serviceState.error != null -> {
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
                                    text = serviceState.error!!,
                                    color = MaterialTheme.colorScheme.onErrorContainer
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                TextButton(
                                    onClick = { serviceViewModel.getServices() }
                                ) {
                                    Text("Erneut versuchen")
                                }
                            }
                        }
                    }

                    serviceState.services.isEmpty() -> {
                        EmptyServicesCustomerCard()
                    }

                    else -> {
                        LazyRow(
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                            contentPadding = PaddingValues(horizontal = 4.dp)
                        ) {
                            items(serviceState.services.take(5)) { service ->
                                Box(
                                    modifier = Modifier.width(300.dp)
                                ) {
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
    }
}

@Composable
private fun WelcomeCustomerHeader(
    totalRequestUpdates: Int,
    acceptedCount: Int,
    rejectedCount: Int,
    completedCount: Int,
    unreadMessagesCount: Int
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            Text(
                text = "Finden Sie den perfekten Service",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Entdecken Sie qualifizierte Dienstleister in Ihrer Nähe",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )

            if (totalRequestUpdates > 0) {
                Spacer(modifier = Modifier.height(16.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    if (acceptedCount > 0) {
                        StatusUpdateChip(
                            count = acceptedCount,
                            label = "Angenommen",
                            icon = Icons.Default.CheckCircle,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }

                    if (rejectedCount > 0) {
                        StatusUpdateChip(
                            count = rejectedCount,
                            label = "Abgelehnt",
                            icon = Icons.Default.Cancel,
                            color = MaterialTheme.colorScheme.error
                        )
                    }

                    if (completedCount > 0) {
                        StatusUpdateChip(
                            count = completedCount,
                            label = "Abgeschlossen",
                            icon = Icons.Default.Done,
                            color = MaterialTheme.colorScheme.tertiary
                        )
                    }
                }
            }

            if (unreadMessagesCount > 0) {
                Spacer(modifier = Modifier.height(12.dp))
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.Chat,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onPrimaryContainer,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "$unreadMessagesCount neue Nachrichten",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
            }
        }
    }
}

@Composable
private fun StatusUpdateChip(
    count: Int,
    label: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    color: androidx.compose.ui.graphics.Color
) {
    Surface(
        color = color.copy(alpha = 0.15f),
        shape = RoundedCornerShape(16.dp)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = color,
                modifier = Modifier.size(16.dp)
            )
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = "$count $label",
                style = MaterialTheme.typography.labelSmall,
                color = color,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SearchBar(onSearchClick: () -> Unit) {
    Card(
        onClick = onSearchClick,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Search,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.outline
            )
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = "Nach Services suchen...",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.outline
            )
        }
    }
}

@Composable
private fun PopularCategoriesCard(
    navController: NavController
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Beliebte Kategorien",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(12.dp))

            val categories = listOf(
                "Webentwicklung" to Icons.Default.Web,
                "Mobile Apps" to Icons.Default.PhoneAndroid,
                "Design" to Icons.Default.Palette,
                "Marketing" to Icons.Default.Campaign,
                "Beratung" to Icons.Default.Psychology,
                "Fotografie" to Icons.Default.PhotoCamera
            )

            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(categories) { (category, icon) ->
                    FilterChip(
                        onClick = {
                            navController.navigate("service_list?category=$category")
                        },
                        label = { Text(category) },
                        selected = false,
                        leadingIcon = {
                            Icon(
                                imageVector = icon,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun EmptyServicesCustomerCard() {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
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
                text = "Keine Services verfügbar",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Es sind noch keine Dienstleistungen verfügbar. Schauen Sie später wieder vorbei!",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.outline
            )
        }
    }
}

@Composable
private fun QuickActionsCustomerCard(
    navController: NavController,
    requestUpdatesCount: Int,
    unreadMessagesCount: Int
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Schnellzugriff",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = { navController.navigate(Screen.ServiceList.route) },
                    modifier = Modifier.weight(1f)
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.padding(vertical = 4.dp)
                    ) {
                        Icon(Icons.Default.Search, contentDescription = null)
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Services",
                            style = MaterialTheme.typography.labelSmall,
                            maxLines = 1
                        )
                    }
                }

                OutlinedButton(
                    onClick = { navController.navigate(Screen.RequestList.createRoute(isProvider = false)) },
                    modifier = Modifier.weight(1f)
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.padding(vertical = 4.dp)
                    ) {
                        BadgedBox(
                            badge = {
                                if (requestUpdatesCount > 0) {
                                    Badge {
                                        Text(
                                            text = if (requestUpdatesCount > 9) "9+" else requestUpdatesCount.toString(),
                                            style = MaterialTheme.typography.labelSmall
                                        )
                                    }
                                }
                            }
                        ) {
                            Icon(Icons.Default.RequestQuote, contentDescription = null)
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Anfragen",
                            style = MaterialTheme.typography.labelSmall,
                            maxLines = 1
                        )
                    }
                }

                OutlinedButton(
                    onClick = { navController.navigate(Screen.ChatList.route) },
                    modifier = Modifier.weight(1f)
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.padding(vertical = 4.dp)
                    ) {
                        BadgedBox(
                            badge = {
                                if (unreadMessagesCount > 0) {
                                    Badge {
                                        Text(
                                            text = if (unreadMessagesCount > 9) "9+" else unreadMessagesCount.toString(),
                                            style = MaterialTheme.typography.labelSmall
                                        )
                                    }
                                }
                            }
                        ) {
                            Icon(Icons.AutoMirrored.Filled.Chat, contentDescription = null)
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Nachrichten",
                            fontSize = 10.sp,
                            maxLines = 1,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }
        }
    }
}