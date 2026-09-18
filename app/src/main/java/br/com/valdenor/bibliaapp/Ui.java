package br.com.valdenor.bibliaapp;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Typeface;
import android.util.TypedValue;
import android.view.Gravity;
import android.widget.LinearLayout;
import android.widget.TextView;

import java.util.Locale;

final class Ui {
    private Ui() {}

    static final String PREF_THEME = "settings";
    private static final String KEY_NIGHT = "night";
    private static final String KEY_THEME = "theme";
    private static final String KEY_FONT = "font_scale";

    static final int THEME_LIGHT = 0;
    static final int THEME_DARK = 1;
    static final int THEME_BROWN = 2;
    static final String[] THEME_NAMES = {"Claro", "Escuro", "Marrom"};

    static int themeMode = THEME_LIGHT;
    static int BG;
    static int CARD;
    static int TEXT;
    static int MUTED;
    static int PRIMARY;
    static int PRIMARY_DARK;
    static int ACCENT;
    static int ACCENT_DARK;
    static int LIGHT;
    static int TAB_SELECTED;
    static float FONT_SCALE = 1.0f;

    static final float[] FONT_LEVELS = {0.85f, 1.0f, 1.15f, 1.30f};
    static final String[] FONT_LEVEL_NAMES = {"Pequeno", "Normal", "Grande", "Extra grande"};

    static void init(Context ctx) {
        FONT_SCALE = ctx.getSharedPreferences(PREF_THEME, 0).getFloat(KEY_FONT, 1.0f);
        if (FONT_SCALE < FONT_LEVELS[0]) FONT_SCALE = FONT_LEVELS[0];
        if (FONT_SCALE > FONT_LEVELS[FONT_LEVELS.length - 1]) FONT_SCALE = FONT_LEVELS[FONT_LEVELS.length - 1];
        int saved = ctx.getSharedPreferences(PREF_THEME, 0).getInt(KEY_THEME, -1);
        if (saved < 0) {
            saved = ctx.getSharedPreferences(PREF_THEME, 0).getBoolean(KEY_NIGHT, false) ? THEME_DARK : THEME_LIGHT;
        }
        applyTheme(saved);
    }

    static void applyTheme(int mode) {
        themeMode = mode;
        switch (mode) {
            case THEME_BROWN:
                BG = Color.parseColor("#FBF4E6");
                CARD = Color.parseColor("#FFFDF7");
                TEXT = Color.parseColor("#4A361F");
                MUTED = Color.parseColor("#9B7B4F");
                PRIMARY = Color.parseColor("#A5702C");
                PRIMARY_DARK = Color.parseColor("#7C5218");
                ACCENT = Color.parseColor("#D9A034");
                ACCENT_DARK = Color.parseColor("#B07C1E");
                LIGHT = Color.parseColor("#F2E6CC");
                TAB_SELECTED = Color.parseColor("#BC8A3C");
                break;
            case THEME_DARK:
                BG = Color.parseColor("#121212");
                CARD = Color.parseColor("#1E1E1E");
                TEXT = Color.parseColor("#E6E6E6");
                MUTED = Color.parseColor("#9E9E9E");
                PRIMARY = Color.parseColor("#5B9BD5");
                PRIMARY_DARK = Color.parseColor("#0F2537");
                ACCENT = Color.parseColor("#F5A623");
                ACCENT_DARK = Color.parseColor("#C0841A");
                LIGHT = Color.parseColor("#2A2A2A");
                TAB_SELECTED = Color.parseColor("#2D5C8A");
                break;
            default:
                BG = Color.parseColor("#FAFAFB");
                CARD = Color.parseColor("#FFFFFF");
                TEXT = Color.parseColor("#1B1B1F");
                MUTED = Color.parseColor("#6B7280");
                PRIMARY = Color.parseColor("#154360");
                PRIMARY_DARK = Color.parseColor("#0E2E44");
                ACCENT = Color.parseColor("#E67E22");
                ACCENT_DARK = Color.parseColor("#B45309");
                LIGHT = Color.parseColor("#EEF2F6");
                TAB_SELECTED = Color.parseColor("#1F5E93");
                break;
        }
    }

    static int accentForMode(int mode) {
        switch (mode) {
            case THEME_BROWN: return Color.parseColor("#A5702C");
            case THEME_DARK: return Color.parseColor("#F5A623");
            default: return Color.parseColor("#E67E22");
        }
    }

    static int fontLevelIndex() {
        for (int i = 0; i < FONT_LEVELS.length; i++) {
            if (Math.abs(FONT_LEVELS[i] - FONT_SCALE) < 0.001f) return i;
        }
        return 1;
    }

    static void saveTheme(Context ctx, int mode) {
        ctx.getSharedPreferences(PREF_THEME, 0).edit().putInt(KEY_THEME, mode).apply();
    }

    static void saveFontScale(Context ctx, float scale) {
        ctx.getSharedPreferences(PREF_THEME, 0).edit().putFloat(KEY_FONT, scale).apply();
    }

    static int sp(Context c, float value) {
        return Math.round(TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_SP, value * FONT_SCALE, c.getResources().getDisplayMetrics()));
    }

    static int dp(Context c, float v) {
        return Math.round(v * c.getResources().getDisplayMetrics().density);
    }

    static TextView text(Context c, String s, float sp, int color, boolean bold) {
        TextView t = new TextView(c);
        t.setText(s);
        t.setTextSize(TypedValue.COMPLEX_UNIT_SP, sp * FONT_SCALE);
        t.setTextColor(color);
        t.setTypeface(Typeface.DEFAULT, bold ? Typeface.BOLD : Typeface.NORMAL);
        t.setAutoLinkMask(0);
        return t;
    }

    static TextView textMono(Context c, String s, float sp, int color, boolean bold) {
        TextView t = new TextView(c);
        t.setText(s);
        t.setTextSize(TypedValue.COMPLEX_UNIT_SP, sp * FONT_SCALE);
        t.setTextColor(color);
        t.setTypeface(Typeface.MONOSPACE, bold ? Typeface.BOLD : Typeface.NORMAL);
        return t;
    }

    static LinearLayout column(Context c) {
        LinearLayout l = new LinearLayout(c);
        l.setOrientation(LinearLayout.VERTICAL);
        return l;
    }

    static LinearLayout row(Context c) {
        LinearLayout l = new LinearLayout(c);
        l.setOrientation(LinearLayout.HORIZONTAL);
        return l;
    }

    static LinearLayout vSpace(Context c, int dp) {
        LinearLayout s = new LinearLayout(c);
        s.setLayoutParams(new LinearLayout.LayoutParams(1, dp(c, dp)));
        return s;
    }

    static LinearLayout hSpace(Context c, int dp) {
        LinearLayout s = new LinearLayout(c);
        s.setLayoutParams(new LinearLayout.LayoutParams(dp(c, dp), 1));
        return s;
    }

    static TextView header(Context c, String s) {
        TextView t = text(c, s, 13, PRIMARY, true);
        t.setPadding(dp(c, 16), dp(c, 12), dp(c, 16), dp(c, 4));
        return t;
    }
}