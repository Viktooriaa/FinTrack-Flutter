package com.example.fintrack

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "fintrack/receipt_capture"
    private val cameraRequestCode = 4201
    private val galleryRequestCode = 4202
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (pendingResult != null) {
                    result.error("busy", "A receipt image request is already active.", null)
                    return@setMethodCallHandler
                }

                val intent = when (call.method) {
                    "capture" -> Intent(MediaStore.ACTION_IMAGE_CAPTURE)
                    "gallery" -> Intent(Intent.ACTION_GET_CONTENT).apply {
                        type = "image/*"
                    }
                    else -> null
                }
                if (intent == null) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val requestCode = if (call.method == "capture") cameraRequestCode else galleryRequestCode
                pendingResult = result
                try {
                    startActivityForResult(intent, requestCode)
                } catch (error: ActivityNotFoundException) {
                    pendingResult = null
                    result.error("unavailable", "No app can provide a receipt image.", null)
                } catch (error: Exception) {
                    pendingResult = null
                    result.error("launch_failed", error.message, null)
                }
            }
    }

    @Deprecated("Deprecated in Android, kept for the Flutter method-channel activity result flow")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != cameraRequestCode && requestCode != galleryRequestCode) return

        val response = pendingResult ?: return
        pendingResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            response.success(null)
            return
        }

        try {
            val imageBytes = if (requestCode == cameraRequestCode) {
                (data.extras?.get("data") as? Bitmap)?.let(::compressBitmap)
            } else {
                data.data?.let(::readImage)
            }
            response.success(imageBytes)
        } catch (error: Exception) {
            response.error("read_failed", error.message, null)
        }
    }

    private fun readImage(uri: Uri): ByteArray? {
        val bitmap = contentResolver.openInputStream(uri)?.use { input ->
            BitmapFactory.decodeStream(input)
        }
            ?: return null
        return compressBitmap(bitmap)
    }

    private fun compressBitmap(bitmap: Bitmap): ByteArray {
        val maxDimension = 1800
        val longestSide = maxOf(bitmap.width, bitmap.height)
        val scaled = if (longestSide > maxDimension) {
            val ratio = maxDimension.toFloat() / longestSide
            Bitmap.createScaledBitmap(
                bitmap,
                (bitmap.width * ratio).toInt().coerceAtLeast(1),
                (bitmap.height * ratio).toInt().coerceAtLeast(1),
                true,
            )
        } else {
            bitmap
        }
        return ByteArrayOutputStream().use { output ->
            scaled.compress(Bitmap.CompressFormat.JPEG, 84, output)
            if (scaled !== bitmap) scaled.recycle()
            output.toByteArray()
        }
    }
}
