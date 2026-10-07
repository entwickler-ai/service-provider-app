package com.findurdevkotlin.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.findurdevkotlin.ui.auth.AuthViewModel
import com.findurdevkotlin.ui.auth.LoginScreen
import com.findurdevkotlin.ui.auth.RegisterScreen
import com.findurdevkotlin.ui.auth.RoleSelectionScreen
import com.findurdevkotlin.ui.chat.ChatDetailScreen
import com.findurdevkotlin.ui.chat.ChatListScreen
import com.findurdevkotlin.ui.home.CustomerHomeScreen
import com.findurdevkotlin.ui.home.ProviderHomeScreen
import com.findurdevkotlin.ui.profile.ProfileScreen
import com.findurdevkotlin.ui.request.RequestCreateScreen
import com.findurdevkotlin.ui.request.RequestDetailScreen
import com.findurdevkotlin.ui.request.RequestListScreen
import com.findurdevkotlin.ui.review.CustomerReviewScreen
import com.findurdevkotlin.ui.service.ServiceCreateScreen
import com.findurdevkotlin.ui.service.ServiceDetailScreen
import com.findurdevkotlin.ui.service.ServiceEditScreen
import com.findurdevkotlin.ui.service.ServiceListScreen

sealed class Screen(val route: String) {
    object Login : Screen("login")
    object Register : Screen("register")
    object RoleSelection : Screen("role_selection/{email}/{password}/{name}") {
        fun createRoute(email: String, password: String, name: String) =
            "role_selection/$email/$password/$name"
    }
    object Profile : Screen("profile")
    object CustomerHome : Screen("customer_home")
    object ProviderHome : Screen("provider_home")
    object ServiceCreate : Screen("service_create")
    object ServiceList : Screen("service_list?category={category}")
    object ServiceDetail : Screen("service_detail/{serviceId}") {
        fun createRoute(serviceId: String) = "service_detail/$serviceId"
    }
    object ServiceEdit : Screen("service_edit/{serviceId}") {
        fun createRoute(serviceId: String) = "service_edit/$serviceId"
    }
    object ChatList : Screen("chat_list")
    object ChatDetail : Screen("chat_detail/{chatId}") {
        fun createRoute(chatId: String) = "chat_detail/$chatId"
    }
    object RequestCreate : Screen("request_create/{serviceId}/{serviceTitle}/{providerId}/{providerName}") {
        fun createRoute(
            serviceId: String,
            serviceTitle: String,
            providerId: String,
            providerName: String
        ) = "request_create/$serviceId/$serviceTitle/$providerId/$providerName"
    }
    object RequestList : Screen("request_list?isProvider={isProvider}") {
        fun createRoute(isProvider: Boolean = false) = "request_list?isProvider=$isProvider"
    }
    object RequestDetail : Screen("request_detail/{requestId}") {
        fun createRoute(requestId: String) = "request_detail/$requestId"
    }

    object CustomerReview : Screen("customer_review/{requestId}") {
        fun createRoute(requestId: String) = "customer_review/$requestId"
    }
}

@Composable
fun AppNavHost(navController: NavHostController, viewModel: AuthViewModel = hiltViewModel()) {
    NavHost(navController = navController, startDestination = Screen.Login.route) {
        composable(Screen.Login.route) {
            LoginScreen(navController = navController, viewModel = viewModel)
        }

        composable(Screen.Register.route) {
            RegisterScreen(navController = navController)
        }

        composable(
            Screen.RoleSelection.route,
            arguments = listOf(
                navArgument("email") { type = NavType.StringType },
                navArgument("password") { type = NavType.StringType },
                navArgument("name") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            RoleSelectionScreen(
                navController = navController,
                viewModel = viewModel,
                email = backStackEntry.arguments?.getString("email") ?: "",
                password = backStackEntry.arguments?.getString("password") ?: "",
                name = backStackEntry.arguments?.getString("name") ?: ""
            )
        }

        composable(Screen.Profile.route) {
            ProfileScreen(navController = navController)
        }

        composable(Screen.CustomerHome.route) {
            CustomerHomeScreen(navController = navController)
        }

        composable(Screen.ProviderHome.route) {
            ProviderHomeScreen(navController = navController)
        }

        composable(Screen.ServiceCreate.route) {
            ServiceCreateScreen(navController = navController)
        }

        composable(
            Screen.ServiceList.route,
            arguments = listOf(
                navArgument("category") {
                    type = NavType.StringType
                    nullable = true
                    defaultValue = null
                }
            )
        ) { backStackEntry ->
            val category = backStackEntry.arguments?.getString("category")
            ServiceListScreen(
                navController = navController,
                initialCategory = category
            )
        }

        composable(
            Screen.ServiceDetail.route,
            arguments = listOf(
                navArgument("serviceId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val serviceId = backStackEntry.arguments?.getString("serviceId") ?: ""
            ServiceDetailScreen(navController = navController, serviceId = serviceId)
        }

        composable(
            Screen.ServiceEdit.route,
            arguments = listOf(
                navArgument("serviceId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val serviceId = backStackEntry.arguments?.getString("serviceId") ?: ""
            ServiceEditScreen(navController = navController, serviceId = serviceId)
        }

        composable(Screen.ChatList.route) {
            ChatListScreen(navController = navController)
        }

        composable(
            Screen.ChatDetail.route,
            arguments = listOf(
                navArgument("chatId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val chatId = backStackEntry.arguments?.getString("chatId") ?: ""
            ChatDetailScreen(navController = navController, chatId = chatId)
        }

        composable(
            Screen.RequestCreate.route,
            arguments = listOf(
                navArgument("serviceId") { type = NavType.StringType },
                navArgument("serviceTitle") { type = NavType.StringType },
                navArgument("providerId") { type = NavType.StringType },
                navArgument("providerName") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val serviceId = backStackEntry.arguments?.getString("serviceId") ?: ""
            val serviceTitle = backStackEntry.arguments?.getString("serviceTitle") ?: ""
            val providerId = backStackEntry.arguments?.getString("providerId") ?: ""
            val providerName = backStackEntry.arguments?.getString("providerName") ?: ""

            RequestCreateScreen(
                navController = navController,
                serviceId = serviceId,
                serviceTitle = serviceTitle,
                providerId = providerId,
                providerName = providerName
            )
        }

        composable(
            Screen.RequestList.route,
            arguments = listOf(
                navArgument("isProvider") {
                    type = NavType.BoolType
                    defaultValue = false
                }
            )
        ) { backStackEntry ->
            val isProvider = backStackEntry.arguments?.getBoolean("isProvider") ?: false
            RequestListScreen(navController = navController, isProvider = isProvider)
        }

        composable(
            Screen.RequestDetail.route,
            arguments = listOf(
                navArgument("requestId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val requestId = backStackEntry.arguments?.getString("requestId") ?: ""
            RequestDetailScreen(navController = navController, requestId = requestId)
        }

        composable(
            Screen.CustomerReview.route,
            arguments = listOf(
                navArgument("requestId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val requestId = backStackEntry.arguments?.getString("requestId") ?: ""
            CustomerReviewScreen(navController = navController, requestId = requestId)
        }

        composable(
            route = "service_list?category={category}",
            arguments = listOf(
                navArgument("category") {
                    type = NavType.StringType
                    nullable = true
                }
            )
        ) { backStackEntry ->
            val category = backStackEntry.arguments?.getString("category")
            ServiceListScreen(
                navController = navController,
                viewModel = hiltViewModel(),
                initialCategory = category
            )
        }
    }

    val authState by viewModel.authState.collectAsState()
    val userRole by viewModel.userRole.collectAsState()

    LaunchedEffect(authState.isSuccess, userRole) {
        if (authState.isSuccess && userRole != null) {
            when (userRole) {
                "customer" -> navController.navigate(Screen.CustomerHome.route) {
                    popUpTo(Screen.Login.route) { inclusive = true }
                }
                "provider" -> navController.navigate(Screen.ProviderHome.route) {
                    popUpTo(Screen.Login.route) { inclusive = true }
                }
            }
        }
    }
}