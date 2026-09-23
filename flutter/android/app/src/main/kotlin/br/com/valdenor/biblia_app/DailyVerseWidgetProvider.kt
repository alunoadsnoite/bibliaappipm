package br.com.valdenor.biblia_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.google.gson.Gson
import java.io.InputStream
import java.io.InputStreamReader
import java.util.Calendar

class DailyVerseWidgetProvider : AppWidgetProvider() {

    private val PREFS_NAME = "flutter_shared_preferences"
    private val VERSION_KEY = "biblia_version"
    private val WIDGET_CHANNEL = "br.com.valdenor.bibliaapp/widget"

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: android.content.Intent) {
        super.onReceive(context, intent)
        if (intent.action == WIDGET_CHANNEL || intent.action == android.content.Intent.ACTION_DATE_CHANGED) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, DailyVerseWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            for (appWidgetId in appWidgetIds) {
                updateWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_daily_verse)

        val (verseText, verseRef) = getDailyVerse(context)
        views.setTextViewText(R.id.widget_verse_text, verseText)
        views.setTextViewText(R.id.widget_verse_ref, verseRef)

        val intent = android.content.Intent(context, MainActivity::class.java)
        intent.action = android.content.Intent.ACTION_MAIN
        intent.addCategory(android.content.Intent.CATEGORY_LAUNCHER)
        val pendingIntent = android.app.PendingIntent.getActivity(
            context, 0, intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun getDailyVerse(context: Context): Pair<String, String> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val version = prefs.getString(VERSION_KEY, "ara") ?: "ara"

        val assetName = when (version) {
            "ara" -> "assets/biblia_ara.json"
            "nvi" -> "assets/biblia_nvi.json"
            "ntlh" -> "assets/biblia_ntlh.json"
            "jfaal" -> "assets/biblia.json"
            "bkj" -> "assets/biblia_bkj.json"
            else -> "assets/biblia.json"
        }

        val (bookIdx, chapterIdx, verseIdx) = calculateDailyVerse()
        val verse = loadVerseFromAsset(context, assetName, bookIdx, chapterIdx, verseIdx)
        val ref = formatReference(version, bookIdx, chapterIdx, verseIdx)

        return Pair(verse, ref)
    }

    private fun calculateDailyVerse(): Triple<Int, Int, Int> {
        val dailyVerses = listOf(
            Triple(0, 0, 0),    // Gênesis 1:1
            Triple(1, 13, 13),  // Êxodo 14:14
            Triple(4, 30, 5),   // Deuteronômio 31:6
            Triple(5, 0, 8),    // Josué 1:9
            Triple(18, 0, 0),   // Salmos 1:1
            Triple(18, 22, 0),  // Salmos 23:1
            Triple(18, 22, 3),  // Salmos 23:4
            Triple(18, 45, 0),  // Salmos 46:1
            Triple(18, 118, 104), // Salmos 119:105
            Triple(18, 118, 10),  // Salmos 119:11
            Triple(19, 2, 4),   // Provérbios 3:5
            Triple(19, 2, 5),   // Provérbios 3:6
            Triple(22, 25, 2),  // Isaías 26:3
            Triple(22, 39, 30), // Isaías 40:31
            Triple(22, 40, 9),  // Isaías 41:10
            Triple(23, 28, 10), // Jeremias 29:11
            Triple(39, 4, 15),  // Mateus 5:16
            Triple(39, 5, 32),  // Mateus 6:33
            Triple(39, 10, 27), // Mateus 11:28
            Triple(40, 9, 26),  // Marcos 10:27
            Triple(41, 0, 36),  // Lucas 1:37
            Triple(42, 0, 0),   // João 1:1
            Triple(42, 2, 15),  // João 3:16
            Triple(42, 13, 5),  // João 14:6
            Triple(42, 14, 4),  // João 15:5
            Triple(44, 4, 7),   // Romanos 5:8
            Triple(44, 7, 27),  // Romanos 8:28
            Triple(44, 11, 1),  // Romanos 12:2
            Triple(45, 12, 3),  // 1 Coríntios 13:4
            Triple(45, 14, 57), // 1 Coríntios 15:58
            Triple(46, 4, 16),  // 2 Coríntios 5:17
            Triple(47, 4, 21),  // Gálatas 5:22
            Triple(48, 1, 7),   // Efésios 2:8
            Triple(49, 3, 5),   // Filipenses 4:6
            Triple(49, 3, 12),  // Filipenses 4:13
            Triple(50, 2, 22),  // Colossenses 3:23
            Triple(51, 4, 17),  // 1 Tessalonicenses 5:18
            Triple(54, 0, 6),   // 2 Timóteo 1:7
            Triple(58, 0, 4),   // Tiago 1:5
            Triple(59, 4, 6),   // 1 Pedro 5:7
            Triple(61, 0, 8),   // 1 João 1:9
            Triple(65, 20, 3),  // Apocalipse 21:4
            Triple(65, 2, 19)   // Apocalipse 3:20
        )

        val cal = Calendar.getInstance()
        val dayOfYear = cal.get(Calendar.DAY_OF_YEAR)
        return dailyVerses[dayOfYear % dailyVerses.size]
    }

    private fun loadVerseFromAsset(
        context: Context,
        assetName: String,
        bookIdx: Int,
        chapterIdx: Int,
        verseIdx: Int
    ): String {
        return try {
            val inputStream: InputStream = context.assets.open(assetName)
            val reader = InputStreamReader(inputStream)
            val books = Gson().fromJson(reader, Array<Book>::class.java)
            reader.close()

            if (bookIdx < books.size) {
                val book = books[bookIdx]
                if (chapterIdx < book.chapters.size) {
                    val chapter = book.chapters[chapterIdx]
                    if (verseIdx < chapter.size) {
                        chapter[verseIdx]
                    } else "Versículo não encontrado"
                } else "Capítulo não encontrado"
            } else "Livro não encontrado"
        } catch (e: Exception) {
            "Erro ao carregar versículo"
        }
    }

    private fun formatReference(version: String, bookIdx: Int, chapterIdx: Int, verseIdx: Int): String {
        val bookAbbrs = mapOf(
            0 to "Gn", 1 to "Ex", 2 to "Lv", 3 to "Nm", 4 to "Dt", 5 to "Js",
            6 to "Jz", 7 to "Rt", 8 to "1Sm", 9 to "2Sm", 10 to "1Rs", 11 to "2Rs",
            12 to "1Cr", 13 to "2Cr", 14 to "Ed", 15 to "Ne", 16 to "Et", 17 to "Jo",
            18 to "Sl", 19 to "Pv", 20 to "Ec", 21 to "Ct", 22 to "Is", 23 to "Jr",
            24 to "Lm", 25 to "Ez", 26 to "Dn", 27 to "Os", 28 to "Jl", 29 to "Am",
            30 to "Ob", 31 to "Jn", 32 to "Mq", 33 to "Na", 34 to "Hc", 35 to "Sf",
            36 to "Ag", 37 to "Zc", 38 to "Ml", 39 to "Mt", 40 to "Mc", 41 to "Lc",
            42 to "Jo", 43 to "At", 44 to "Rm", 45 to "1Co", 46 to "2Co", 47 to "Gl",
            48 to "Ef", 49 to "Fp", 50 to "Cl", 51 to "1Ts", 52 to "2Ts", 53 to "1Tm",
            54 to "2Tm", 55 to "Tt", 56 to "Fm", 57 to "Hb", 58 to "Tg", 59 to "1Pe",
            60 to "2Pe", 61 to "1Jo", 62 to "2Jo", 63 to "3Jo", 64 to "Jd", 65 to "Ap"
        )
        val abbr = bookAbbrs[bookIdx] ?: "Livro"
        return "$abbr ${chapterIdx + 1}:${verseIdx + 1}"
    }

    data class Book(
        val abbr: String,
        val name: String,
        val chapters: List<List<String>>
    )
}