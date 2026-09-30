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
 * O texto e a referência são enviados pelo app Flutter pelo canal
 * `br.com.valdenor.bibliaapp/widget` (ver [MainActivity]) e ficam gravados
 * [PREFS_NAME], um arquivo de preferências que pertence a este widget.
 *
 * Não é possível ler as preferências do `shared_preferences` diretamente
 * daqui: o plugin grava no arquivo "FlutterSharedPreferences" com as chaves
 * prefixadas por "flutter.", ou em DataStore, e nenhum dos dois é contrato
 * estável para um `AppWidgetProvider`.
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
        // Trocar de dia ou fuso invalida o texto salvo, então é preciso
        // redesenhar para o placeholder não ficar horas na tela.
        if (intent.action in RERENDER_ACTIONS) refreshAll(context)
    }

    companion object {
        const val PREFS_NAME = "widget_daily_verse"

        private const val VERSE_TEXT_KEY = "text"
        private const val VERSE_REF_KEY = "ref"
        private const val VERSE_DATE_KEY = "date"

        private const val PLACEHOLDER_TEXT =
            "Abra o app para ver o versículo de hoje."
        private const val PLACEHOLDER_REF = "Bíblia IPM"

        private val RERENDER_ACTIONS = setOf(
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
        )

        /** Data local no mesmo formato `YYYY-MM-DD` usado pelo lado Dart. */
        private fun today(): String =
            SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

        private fun prefs(context: Context): SharedPreferences =
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        /**
         * Grava o versículo recebido do app e redesenha o widget.
         *
         * Usa `commit()` (síncrono) de propósito: o redesenho acontece logo em
         * seguida e precisa enxergar o valor gravado.
         */
        fun sync(context: Context, text: String, ref: String, date: String) {
            prefs(context).edit()
                .putString(VERSE_TEXT_KEY, text)
                .putString(VERSE_REF_KEY, ref)
                .putString(VERSE_DATE_KEY, date)
                .commit()
            refreshAll(context)
        }

        /**
         * Versículo salvo para hoje, ou um texto neutro quando o app ainda não
         * rodou no dia corrente. `SimpleDateFormat` em vez de `java.time`
         * porque `java.time` exige API 26 e o `minSdk` do projeto é menor.
         */
        private fun verseOf(context: Context): Pair<String, String> {
            val prefs = prefs(context)
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
