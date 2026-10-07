package com.findurdevkotlin.ui.auth

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.findurdevkotlin.R
import com.findurdevkotlin.ui.navigation.Screen
import java.util.regex.Pattern

@Composable
fun LoginScreen(navController: NavController, viewModel: AuthViewModel = hiltViewModel()) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var isPasswordVisible by remember { mutableStateOf(false) }

    var emailError by remember { mutableStateOf("") }
    var passwordError by remember { mutableStateOf("") }
    
    val state by viewModel.authState.collectAsState()

    fun validateEmail(email: String): String {
        if (email.isEmpty()) return ""
        
        val emailPattern = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return if (!Pattern.matches(emailPattern, email)) {
            "Bitte gültige Email eingeben"
        } else {
            ""
        }
    }

    fun validatePassword(password: String): String {
        if (password.isEmpty()) return ""
        
        return if (password.length < 6) {
            "Passwort muss mindestens 6 Zeichen lang sein"
        } else {
            ""
        }
    }

    fun validateInputs(): Boolean {
        emailError = validateEmail(email)
        passwordError = validatePassword(password)
        
        return emailError.isEmpty() && passwordError.isEmpty() && 
               email.isNotEmpty() && password.isNotEmpty()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Image(
            painter = painterResource(id = R.drawable.ic_launcher_foreground),
            contentDescription = "App Logo",
            modifier = Modifier
                .padding(bottom = 8.dp)
                .size(180.dp)
        )
        
        Text(
            text = "Service Provider App",
            style = MaterialTheme.typography.headlineLarge,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        
        Text(
            text = "Anmelden",
            style = MaterialTheme.typography.headlineMedium,
            modifier = Modifier.padding(bottom = 32.dp)
        )

        Column {
            TextField(
                value = email,
                onValueChange = { 
                    email = it
                    emailError = validateEmail(it)
                },
                label = { Text("Email") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                isError = emailError.isNotEmpty()
            )
            
            if (emailError.isNotEmpty()) {
                Text(
                    text = emailError,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(start = 16.dp, top = 4.dp)
                )
            }
        }

        Spacer(Modifier.height(8.dp))

        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                TextField(
                    value = password,
                    onValueChange = {
                        password = it
                        passwordError = validatePassword(it)
                    },
                    label = { Text("Passwort") },
                    visualTransformation = if (isPasswordVisible) {
                        VisualTransformation.None
                    } else {
                        PasswordVisualTransformation()
                    },
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    isError = passwordError.isNotEmpty()
                )

                IconButton(
                    onClick = { isPasswordVisible = !isPasswordVisible },
                    modifier = Modifier.size(48.dp)
                ) {
                    Icon(
                        imageVector = if (isPasswordVisible) {
                            Icons.Default.VisibilityOff
                        } else {
                            Icons.Default.Visibility
                        },
                        contentDescription = if (isPasswordVisible) {
                            "Passwort verstecken"
                        } else {
                            "Passwort anzeigen"
                        },
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            if (passwordError.isNotEmpty()) {
                Text(
                    text = passwordError,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(start = 16.dp, top = 4.dp)
                )
            }
        }

        Spacer(Modifier.height(16.dp))

        if (state.isLoading) {
            CircularProgressIndicator()
        } else {
            Button(
                onClick = { 
                    if (validateInputs()) {
                        viewModel.login(email, password)
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = email.isNotEmpty() && password.isNotEmpty() && 
                         emailError.isEmpty() && passwordError.isEmpty()
            ) {
                Text("Anmelden")
            }
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

        Spacer(Modifier.height(24.dp))

        TextButton(onClick = { navController.navigate(Screen.Register.route) }) {
            Text("Noch kein Konto? Registrieren")
        }
    }
}