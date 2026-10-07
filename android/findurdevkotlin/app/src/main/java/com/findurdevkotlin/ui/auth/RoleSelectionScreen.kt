package com.findurdevkotlin.ui.auth

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Work
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController

@Composable
fun RoleSelectionScreen(
    navController: NavController,
    viewModel: AuthViewModel = hiltViewModel(),
    email: String,
    password: String,
    name: String
) {
    val state by viewModel.authState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Wähle deine Rolle",
            style = MaterialTheme.typography.headlineMedium,
            modifier = Modifier.padding(bottom = 32.dp)
        )

        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp)
        ) {
            Button(
                onClick = {
                    viewModel.register(email, password, name, "customer")
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                enabled = !state.isLoading
            ) {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = null,
                    modifier = Modifier.padding(end = 8.dp)
                )
                Text("Ich bin Kunde")
            }
        }

        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp)
        ) {
            Button(
                onClick = {
                    viewModel.register(email, password, name, "provider")
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                enabled = !state.isLoading
            ) {
                Icon(
                    imageVector = Icons.Default.Work,
                    contentDescription = null,
                    modifier = Modifier.padding(end = 8.dp)
                )
                Text("Ich bin Dienstleister")
            }
        }

        Spacer(Modifier.height(24.dp))

        if (state.isLoading) {
            CircularProgressIndicator()
        }

        state.error?.let {
            Card(
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer
                ),
                modifier = Modifier.padding(top = 16.dp)
            ) {
                Text(
                    text = it,
                    color = MaterialTheme.colorScheme.onErrorContainer,
                    modifier = Modifier.padding(16.dp)
                )
            }
        }

        if (state.isSuccess) {
            LaunchedEffect(Unit) {
                viewModel.fetchUserRole()
            }
        }

        Spacer(Modifier.height(16.dp))

        TextButton(
            onClick = { navController.popBackStack() }
        ) {
            Text("Zurück")
        }
    }
}