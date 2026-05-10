package com.example.shadowtrace_app.data.repository

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.example.shadowtrace_app.data.model.User
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor(
    private val auth: FirebaseAuth,
    private val firestore: FirebaseFirestore
) {
    suspend fun login(email: String, pass: String) = auth.signInWithEmailAndPassword(email, pass).await()

    suspend fun signup(name: String, email: String, pass: String, phone: String, guardianPhone: String) {
        val result = auth.createUserWithEmailAndPassword(email, pass).await()
        val user = User(uid = result.user?.uid ?: "", name = name, email = email, phone = phone, guardianPhone = guardianPhone)
        firestore.collection("users").document(user.uid).set(user).await()
    }

    fun getCurrentUser() = auth.currentUser
    
    suspend fun getUserDetails(uid: String): User? {
        return firestore.collection("users").document(uid).get().await().toObject(User::class.java)
    }

    fun logout() = auth.signOut()
}
