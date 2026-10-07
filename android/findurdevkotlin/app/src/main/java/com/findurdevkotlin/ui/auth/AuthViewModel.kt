package com.findurdevkotlin.ui.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.findurdevkotlin.data.repository.AuthRepository
import com.findurdevkotlin.data.model.AuthState
import com.findurdevkotlin.data.model.User
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val repo: AuthRepository
) : ViewModel() {

    private val _authState = MutableStateFlow(AuthState())
    val authState: StateFlow<AuthState> = _authState

    private val _userRole = MutableStateFlow<String?>(null)
    val userRole: StateFlow<String?> = _userRole

    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = _currentUser

    fun register(email: String, password: String, name: String, role: String) {
        viewModelScope.launch {
            _authState.value = AuthState(isLoading = true)
            val result = repo.registerUser(email, password, name, role)
            _authState.value = if (result.isSuccess) {
                AuthState(isSuccess = true)
            } else {
                AuthState(error = result.exceptionOrNull()?.message)
            }
        }
    }

    fun login(email: String, password: String) {
        viewModelScope.launch {
            try {
                _authState.value = AuthState(isLoading = true)
                val result = repo.loginUser(email, password)

                if (result.isSuccess) {
                    val userResult = repo.getCurrentUserInfo()
                    if (userResult.isSuccess) {
                        val user = userResult.getOrNull()
                        _currentUser.value = user
                        _userRole.value = user?.role
                        _authState.value = AuthState(isSuccess = true)
                    } else {
                        _authState.value = AuthState(error = "Fehler beim Laden der Benutzerdaten")
                    }
                } else {
                    _authState.value = AuthState(error = result.exceptionOrNull()?.message)
                }
            } catch (e: Exception) {
                _authState.value = AuthState(error = "Login-Fehler: ${e.message}")
            }
        }
    }

    fun fetchUserRole() {
        viewModelScope.launch {
            try {
                val uid = repo.getCurrentUser()?.uid ?: return@launch
                _userRole.value = repo.getUserRole(uid)
            } catch (_: Exception) {
            }
        }
    }

    fun loadCurrentUser() {
        viewModelScope.launch {
            try {
                if (repo.getCurrentUser() != null) {
                    val result = repo.getCurrentUserInfo()
                    if (result.isSuccess) {
                        val user = result.getOrNull()
                        _currentUser.value = user
                        if (_userRole.value == null) {
                            _userRole.value = user?.role
                        }
                    }
                }
            } catch (_: Exception) {
            }
        }
    }

    fun logout() {
        repo.logout()
        _currentUser.value = null
        _userRole.value = null
        _authState.value = AuthState()
    }
}