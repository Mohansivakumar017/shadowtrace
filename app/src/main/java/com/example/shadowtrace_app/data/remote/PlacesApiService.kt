package com.example.shadowtrace_app.data.remote

import retrofit2.Response
import retrofit2.http.GET
import retrofit2.http.Query

interface PlacesApiService {
    @GET("places/v0/indexes/shadowtrace-index/search/nearby")
    suspend fun getNearbyPlaces(
        @Query("lat") lat: Double,
        @Query("lng") lng: Double,
        @Query("key") apiKey: String
    ): Response<Any> // Simplified for demonstration
}
