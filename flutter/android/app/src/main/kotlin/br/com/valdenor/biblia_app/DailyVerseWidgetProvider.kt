package br.com.valdenor.biblia_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Widget "Versículo do Dia".
 *
 * O texto e a referência são gravados pelo app Flutter em SharedPreferences
 * ([AppState._saveDailyVerse]); o widget apenas os exibe. Não há cópia local da
 * lista de versículos nem leitura do JSON da Bíblia aqui: uma lista embutida
 * desincronizaria do app, e parsear o asset (centenas de KB) na thread principal
 * a cada atualização causaria ANR.
 */
class DailyVerseWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            render(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_REFRESH, Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED -> refreshAll(context)
        }
    }

    companion object {
        // O shared_preferences 2.x grava em "<applicationId>_preferences", e o
        // applicationId vive em android/app/build.gradle.kts. Precisa bater com
        // ele para o widget enxergar o que o app Flutter salvou.
        const val PREFS_NAME = "br.com.valdenor.bibliaapp_preferences"
        const val ACTION_REFRESH = "br.com.valdenor.bibliaapp/widget"

        private const val VERSE_TEXT_KEY = "daily_verse_text"
        private const val VERSE_REF_KEY = "daily_verse_ref"
        private const val VERSE_DATE_KEY = "daily_verse_date"

        private const val PLACEHOLDER_TEXT =
            "Abra o app para ver o versículo de hoje."
        private const val PLACEHOLDER_REF = "Bíblia IPM"

        /** Data local no mesmo formato `YYYY-MM-DD` usado pelo lado Dart. */
        private fun today(): String =
            SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

        /**
         * Versículo salvo para hoje, ou um texto neutro quando o app ainda não
         * rodou no dia corrente. `SimpleDateFormat` em vez de `java.time` porque
         * `java.time` exige API 26 e o `minSdk` do projeto é menor.
         */
        private fun verseOf(context: Context): Pair<String, String> {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            if (prefs.getString(VERSE_DATE_KEY, "") == today()) {
                val text = prefs.getString(VERSE_TEXT_KEY, "").orEmpty()
                val ref = prefs.getString(VERSE_REF_KEY, "").orEmpty()
                if (text.isNotEmpty() && ref.isNotEmpty()) return Pair(text, ref)
            }
            return Pair(PLACEHOLDER_TEXT, PLACEHOLDER_REF)
        }

        private fun render(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_daily_verse)
            val (text, ref) = verseOf(context)
            views.setTextViewText(R.id.widget_verse_text, text)
            views.setTextViewText(R.id.widget_verse_ref, ref)

            val launch = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
            }
            views.setOnClickPendingIntent(
                R.id.widget_root,
                PendingIntent.getActivity(
                    context,
                    0,
                    launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        /** Redesenha todas as instâncias do widget já colocadas na tela. */
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, DailyVerseWidgetProvider::class.java)
            )
            for (id in ids) render(context, manager, id)
        }
    }
}
