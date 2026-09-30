package br.com.valdenor.biblia_app

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val migrationChannel = "br.com.valdenor.bibliaapp/migration"
    private val widgetChannel = "br.com.valdenor.bibliaapp/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, migrationChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "readNativeData" -> result.success(readNativeData())
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // O Flutter acabou de salvar o versículo do dia; redesenha o
                    // widget para não esperar o updatePeriodMillis.
                    "refreshWidget" -> {
                        DailyVerseWidgetProvider.refreshAll(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Lê os dados deixados pelo app nativo (v4.0 e anteriores) que compartilha
     * o mesmo applicationId: preferências "settings" e "highlights" e os
     * arquivos musicas.json / boletim.json em filesDir.
     */
    private fun readNativeData(): Map<String, Any?> {
        val out = HashMap<String, Any?>()

        val highlights = getSharedPreferences("highlights", Context.MODE_PRIVATE)
        val hlMap = HashMap<String, Int>()
        for ((key, value) in highlights.all) {
            if (value is Int) hlMap[key] = value
        }
        out["highlights"] = hlMap

        val settings = getSharedPreferences("settings", Context.MODE_PRIVATE)
        if (settings.contains("theme")) out["theme"] = settings.getInt("theme", 0)
        if (settings.contains("night")) out["night"] = settings.getBoolean("night", false)
        if (settings.contains("font_scale")) {
            out["fontScale"] = settings.getFloat("font_scale", 1.0f).toDouble()
        }
        out["version"] = settings.getString("biblia_version", null)

        out["songs"] = readFile(File(filesDir, "musicas.json"))
        out["boletim"] = readFile(File(filesDir, "boletim.json"))

        return out
    }

    private fun readFile(file: File): String? = try {
        if (file.exists()) file.readText(Charsets.UTF_8) else null
    } catch (e: Exception) {
        null
    }
}