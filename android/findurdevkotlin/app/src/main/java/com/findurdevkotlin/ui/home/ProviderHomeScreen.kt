package com.findurdevkotlin.ui.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.RequestQuote
import androidx.compose.material.icons.filled.Work
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
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
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.findurdevkotlin.ui.auth.AuthViewModel
import com.findurdevkotlin.ui.chat.ChatViewModel
import com.findurdevkotlin.ui.navigation.Screen
import com.findurdevkotlin.ui.request.RequestViewModel
import com.findurdevkotlin.ui.service.ServiceCard
import com.findurdevkotlin.ui.service.ServiceViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProviderHomeScreen(
    navController: NavController,
    authViewModel: AuthViewModel = hiltViewModel(),
    serviceViewModel: ServiceViewModel = hiltViewModel(),
    chatViewModel: ChatViewModel = hiltViewModel(),
    requestViewModel: RequestViewModel = hiltViewModel()
) {
    val serviceState by serviceViewModel.serviceState.collectAsState()
    val totalUnreadCount by chatViewModel.totalUnreadCount.collectAsState()
    val pendingRequestsCount by requestViewModel.pendingRequestsCount.collectAsState()
    val currentUser by authViewModel.currentUser.collectAsState()

    LaunchedEffect(Unit) {
        serviceViewModel.getServicesByProvider()
        requestViewModel.loadPendingRequestsCount(isProvider = true)
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
                        text = "Provider Dashboard",
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
                            if (pendingRequestsCount > 0) {
                                Badge {
                                    Text(
                                        text = if (pendingRequestsCount > 99) "99+" else pendingRequestsCount.toString()
                                    )
                                }
                            }
                        }
                    ) {
                        IconButton(onClick = {
                            navController.navigate(Screen.RequestList.createRoute(isProvider = true))
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
                WelcomeProviderHeader(
                    pendingRequestsCount = pendingRequestsCount,
                    unreadMessagesCount = totalUnreadCount
                )
            }

            item {
                QuickActionsProviderCard(
                    navController = navController,
                    pendingRequestsCount = pendingRequestsCount,
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
                        text = "Meine Services",
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
                                    onClick = { serviceViewModel.getServicesByProvider() }
                                ) {
                                    Text("Erneut versuchen")
                                }
                            }
                        }
                    }

                    serviceState.services.isEmpty() -> {
                        EmptyServicesCard(navController = navController)
                    }

                    else -> {
                        Column {
                            Text(
                                text = "${serviceState.services.size} Services",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.outline
                            )
                            Spacer(modifier = Modifier.height(8.dp))

                            LazyRow(
                                horizontalArrangement = Arrangement.spacedBy(12.dp),
                                contentPadding = PaddingValues(horizontal = 4.dp)
                            ) {
                                items(serviceState.services) { service ->
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

            item {
                Column {
                    Spacer(modifier = Modifier.height(32.dp))

                    Button(
                        onClick = { navController.navigate(Screen.ServiceCreate.route) },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(
                            imageVector = Icons.Default.Add,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Service erstellen")
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                }
            }
        }
    }
}

@Composable
fun WelcomeProviderHeader(
    pendingRequestsCount: Int,
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
                text = "Willkommen zurück!",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Verwalten Sie Ihre Services und Anfragen",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "$pendingRequestsCount",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                    Text(
                        text = "Offene Anfragen",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }

                Column(
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "$unreadMessagesCount",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                    Text(
                        text = "Neue Nachrichten",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
            }
        }
    }
}

@Composable
fun QuickActionsProviderCard(
    navController: NavController,
    pendingRequestsCount: Int,
    unreadMessagesCount: Int
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Schnellaktionen",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = { navController.navigate(Screen.ServiceCreate.route) },
                    modifier = Modifier.weight(1f)
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.padding(vertical = 4.dp)
                    ) {
                        Icon(Icons.Default.Add, contentDescription = null)
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Service erstellen",
                            fontSize = 9.sp,
                            maxLines = 1,
                            textAlign = TextAlign.Center
                        )
                    }
                }

                OutlinedButton(
                    onClick = { navController.navigate(Screen.RequestList.createRoute(isProvider = true)) },
                    modifier = Modifier.weight(1f)
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.padding(vertical = 4.dp)
                    ) {
                        BadgedBox(
                            badge = {
                                if (pendingRequestsCount > 0) {
                                    Badge {
                                        Text(
                                            text = if (pendingRequestsCount > 9) "9+" else pendingRequestsCount.toString(),
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

@Composable
private fun EmptyServicesCard(navController: NavController) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.Work,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.outline
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "Noch keine Services",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Erstellen Sie Ihren ersten Service, um Kunden zu erreichen.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.outline
            )
            Spacer(modifier = Modifier.height(16.dp))
            Button(
                onClick = { navController.navigate(Screen.ServiceCreate.route) }
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Ersten Service erstellen")
            }
        }
    }
}