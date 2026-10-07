package com.findurdevkotlin.di

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.storage.FirebaseStorage
import com.findurdevkotlin.data.repository.*
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideOpenAIService(): OpenAIService = OpenAIService()
    @Provides @Singleton
    fun provideFirebaseAuth(): FirebaseAuth = FirebaseAuth.getInstance()

    @Provides @Singleton
    fun provideFirestore(): FirebaseFirestore {
        val firestore = FirebaseFirestore.getInstance()
        val settings = com.google.firebase.firestore.FirebaseFirestoreSettings.Builder()
            .setPersistenceEnabled(true)
            .setCacheSizeBytes(com.google.firebase.firestore.FirebaseFirestoreSettings.CACHE_SIZE_UNLIMITED)
            .build()
        firestore.firestoreSettings = settings
        return firestore
    }

    @Provides @Singleton
    fun provideFirebaseStorage(): FirebaseStorage = FirebaseStorage.getInstance()

    @Provides @Singleton
    fun provideImageRepository(
        storage: FirebaseStorage
    ): ImageRepository = ImageRepository(storage)

    @Provides @Singleton
    fun provideAuthRepository(
        auth: FirebaseAuth,
        db: FirebaseFirestore
    ): AuthRepository = AuthRepository(auth, db)

    @Provides @Singleton
    fun provideServiceRepository(
        db: FirebaseFirestore
    ): ServiceRepository = ServiceRepository(db)

    @Provides @Singleton
    fun provideChatRepository(
        db: FirebaseFirestore
    ): ChatRepository = ChatRepository(db)

    @Provides @Singleton
    fun provideRequestRepository(
        db: FirebaseFirestore
    ): RequestRepository = RequestRepository(db)

    @Provides @Singleton
    fun provideReviewRepository(
        db: FirebaseFirestore
    ): ReviewRepository = ReviewRepository(db)
}