package com.example.dualio

import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.net.Uri
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dualio/clipboard")
            .setMethodCallHandler { call, result ->
                if (call.method == "readClipboard") {
                    result.success(readClipboard())
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun readClipboard(): Map<String, Any?> {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = clipboard.primaryClip ?: return mapOf("type" to "empty")
        if (clip.itemCount == 0) {
            return mapOf("type" to "empty")
        }

        val description = clipboard.primaryClipDescription ?: clip.description
        for (index in 0 until clip.itemCount) {
            val uri = clip.getItemAt(index).uri ?: continue
            val mimeType = imageMimeTypeFor(uri, description) ?: continue
            val path = copyClipboardImage(uri, mimeType) ?: continue
            return mapOf("type" to "image", "path" to path, "mimeType" to mimeType)
        }

        for (index in 0 until clip.itemCount) {
            val text = clip.getItemAt(index).coerceToText(this)?.toString()?.trim()
            if (!text.isNullOrEmpty()) {
                return mapOf("type" to "text", "text" to text)
            }
        }

        return mapOf("type" to "unsupported")
    }

    private fun imageMimeTypeFor(uri: Uri, description: ClipDescription?): String? {
        val resolved = contentResolver.getType(uri)
        if (resolved?.startsWith("image/") == true) {
            return resolved
        }

        if (description == null) {
            return null
        }

        for (index in 0 until description.mimeTypeCount) {
            val mimeType = description.getMimeType(index)
            if (mimeType.startsWith("image/")) {
                return if (mimeType == "image/*") "image/jpeg" else mimeType
            }
        }
        return null
    }

    private fun copyClipboardImage(uri: Uri, mimeType: String): String? {
        return try {
            val extension = extensionForMimeType(mimeType)
            val directory = File(cacheDir, "clipboard")
            directory.mkdirs()
            val outputFile = File(
                directory,
                "clipboard-${System.currentTimeMillis()}.$extension",
            )

            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(outputFile).use { output ->
                    input.copyTo(output)
                }
            } ?: return null

            outputFile.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    private fun extensionForMimeType(mimeType: String): String {
        val extension = MimeTypeMap.getSingleton()
            .getExtensionFromMimeType(mimeType)
            ?.lowercase()
            ?.takeIf { it.matches(Regex("[a-z0-9]+")) }
        return when (extension) {
            "jpeg" -> "jpg"
            null -> "jpg"
            else -> extension
        }
    }
}
