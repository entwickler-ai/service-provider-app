package com.findurdevkotlin.ui.auth

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.findurdevkotlin.ui.navigation.Screen
import com.findurdevkotlin.R
import java.util.regex.Pattern

@Composable
fun RegisterScreen(navController: NavController) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var name by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }

    var isPasswordVisible by remember { mutableStateOf(false) }
    var isConfirmPasswordVisible by remember { mutableStateOf(false) }

    var nameError by remember { mutableStateOf("") }
    var emailError by remember { mutableStateOf("") }
    var passwordError by remember { mutableStateOf("") }
    var confirmPasswordError by remember { mutableStateOf("") }

    fun validateName(name: String): String {
        if (name.isEmpty()) return ""

        return if (name.trim().length < 2) {
            "Name muss mindestens 2 Zeichen lang sein"
        } else {
            ""
        }
    }

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

    fun validateConfirmPassword(confirmPassword: String): String {
        if (confirmPassword.isEmpty()) return ""

        return if (confirmPassword != password) {
            "Passwörter stimmen nicht überein"
        } else {
            ""
        }
    }

    fun isFormValid(): Boolean {
        return name.isNotEmpty() &&
                email.isNotEmpty() &&
                password.isNotEmpty() &&
                confirmPassword.isNotEmpty() &&
                nameError.isEmpty() &&
                emailError.isEmpty() &&
                passwordError.isEmpty() &&
                confirmPasswordError.isEmpty()
    }

    fun validateAllInputs(): Boolean {
        nameError = validateName(name)
        emailError = validateEmail(email)
        passwordError = validatePassword(password)
        confirmPasswordError = validateConfirmPassword(confirmPassword)

        return isFormValid()
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
            text = "Registrieren",
            style = MaterialTheme.typography.headlineMedium,
            modifier = Modifier.padding(bottom = 24.dp),
            textAlign = TextAlign.Center
        )

        Column(
            modifier = Modifier.fillMaxWidth()
        ) {
            TextField(
                value = name,
                onValueChange = {
                    name = it
                    nameError = validateName(it)
                },
                label = { Text("Name") },
                modifier = Modifier.fillMaxWidth(),
                isError = nameError.isNotEmpty()
            )

            if (nameError.isNotEmpty()) {
                Text(
                    text = nameError,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(start = 16.dp, top = 4.dp)
                )
            }
        }

        Spacer(Modifier.height(8.dp))

        Column(
            modifier = Modifier.fillMaxWidth()
        ) {
            TextField(
                value = email,
                onValueChange = {
                    email = it
                    emailError = validateEmail(it)
                },
                label = { Text("Email") },
                modifier = Modifier.fillMaxWidth(),
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

        Column(
            modifier = Modifier.fillMaxWidth()
        ) {
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
                        if (confirmPassword.isNotEmpty()) {
                            confirmPasswordError = validateConfirmPassword(confirmPassword)
                        }
                    },
                    label = { Text("Passwort") },
                    visualTransformation = if (isPasswordVisible) {
                        VisualTransformation.None
                    } else {
                        PasswordVisualTransformation()
                    },
                    modifier = Modifier.weight(1f),
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

        Spacer(Modifier.height(8.dp))

        Column(
            modifier = Modifier.fillMaxWidth()
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                TextField(
                    value = confirmPassword,
                    onValueChange = {
                        confirmPassword = it
                        confirmPasswordError = validateConfirmPassword(it)
                    },
                    label = { Text("Passwort bestätigen") },
                    visualTransformation = if (isConfirmPasswordVisible) {
                        VisualTransformation.None
                    } else {
                        PasswordVisualTransformation()
                    },
                    modifier = Modifier.weight(1f),
                    isError = confirmPasswordError.isNotEmpty()
                )

                IconButton(
                    onClick = { isConfirmPasswordVisible = !isConfirmPasswordVisible },
                    modifier = Modifier.size(48.dp)
                ) {
                    Icon(
                        imageVector = if (isConfirmPasswordVisible) {
                            Icons.Default.VisibilityOff
                        } else {
                            Icons.Default.Visibility
                        },
                        contentDescription = if (isConfirmPasswordVisible) {
                            "Passwort verstecken"
                        } else {
                            "Passwort anzeigen"
                        },
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            if (confirmPasswordError.isNotEmpty()) {
                Text(
                    text = confirmPasswordError,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(start = 16.dp, top = 4.dp)
                )
            }
        }

        Spacer(Modifier.height(16.dp))

        Button(
            onClick = {
                if (validateAllInputs()) {
                    navController.navigate(Screen.RoleSelection.createRoute(email, password, name))
                }
            },
            modifier = Modifier.fillMaxWidth(),
            enabled = isFormValid()
        ) {
            Text("Weiter zur Rollenwahl")
        }

        Spacer(Modifier.height(16.dp))

        TextButton(
            onClick = { navController.popBackStack() },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(
                text = "Bereits ein Konto? Zur Anmelden",
                textAlign = TextAlign.Center
            )
        }
    }
}