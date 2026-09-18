package br.com.valdenor.bibliaapp;

import android.content.Context;

final class Highlights {
    static final String[] COLORS = {
            "#F3D463", // amarelo
            "#8ED9B0", // verde
            "#F2A9A9", // vermelho
            "#A9C4F2", // azul
            "#D5B8F2", // roxo
            "#F2A9DC"  // rosa
    };
    static final String[] COLOR_NAMES = {
            "Amarelo", "Verde", "Vermelho", "Azul", "Roxo", "Rosa"
    };
    private static final String PREFS = "highlights";

    private Highlights() {}

    static int get(Context ctx, String key) {
        return ctx.getSharedPreferences(PREFS, 0).getInt(key, -1);
    }

    static void set(Context ctx, String key, int colorIndex) {
        ctx.getSharedPreferences(PREFS, 0).edit().putInt(key, colorIndex).apply();
    }

    static void remove(Context ctx, String key) {
        ctx.getSharedPreferences(PREFS, 0).edit().remove(key).apply();
    }
}