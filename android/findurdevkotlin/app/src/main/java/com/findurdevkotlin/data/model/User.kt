package com.findurdevkotlin.data.model

data class User(
    val uid: String = "",
    val name: String = "",
    val email: String = "",
    val role: String = "",
    val profileImage: String = "",
    val description: String = "",
    val location: String = ""
)