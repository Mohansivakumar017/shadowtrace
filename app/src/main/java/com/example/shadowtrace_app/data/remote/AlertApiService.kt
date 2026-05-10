package com.example.shadowtrace_app.data.remote

import com.example.shadowtrace_app.data.model.AlertRequest
import com.example.shadowtrace_app.data.model.AlertResponse
import com.example.shadowtrace_app.data.model.RespondRequest
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.POST

interface AlertApiService {
    @POST("trigger-alert")
    suspend fun triggerAlert(@Body request: AlertRequest): Response<AlertResponse>

    @POST("respond-alert")
    suspend fun respondToAlert(@Body request: RespondRequest): Response<AlertResponse>
}
