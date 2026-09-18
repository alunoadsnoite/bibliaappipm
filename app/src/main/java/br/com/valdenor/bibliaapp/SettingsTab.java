package br.com.valdenor.bibliaapp;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.view.Gravity;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.TextView;

import java.util.Locale;

class SettingsTab {

    private final Activity act;
    private final View view;

    SettingsTab(Activity a) {
        act = a;

        LinearLayout root = Ui.column(act);
        root.setBackgroundColor(Ui.BG);
        root.setPadding(Ui.dp(act, 16), Ui.dp(act, 12), Ui.dp(act, 16), Ui.dp(act, 24));

        TextView title = Ui.text(act, "Configurações", 20, Ui.TEXT, true);
        title.setGravity(Gravity.CENTER_HORIZONTAL);
        root.addView(title);
        root.addView(Ui.vSpace(act, 6));

        TextView about = Ui.text(act, AppInfo.NAME + " - versão " + AppInfo.VERSION, 13, Ui.MUTED, false);
        about.setGravity(Gravity.CENTER_HORIZONTAL);
        root.addView(about);
        root.addView(Ui.vSpace(act, 18));

        root.addView(Ui.text(act, "Tamanho da letra", 15, Ui.TEXT, true));

        TextView value = Ui.text(act, "", 14, Ui.ACCENT, false);
        value.setGravity(Gravity.CENTER_HORIZONTAL);
        root.addView(value);

        SeekBar bar = new SeekBar(act);
        bar.setMax(Ui.FONT_LEVELS.length - 1);
        bar.setProgress(Ui.fontLevelIndex());
        root.addView(bar);

        LinearLayout ticks = Ui.row(act);
        for (String n : Ui.FONT_LEVEL_NAMES) {
            TextView t = Ui.text(act, n, 12, Ui.MUTED, false);
            t.setGravity(Gravity.CENTER);
            ticks.addView(t, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));
        }
        root.addView(ticks);

        LinearLayout previewBox = Ui.column(act);
        previewBox.setBackgroundColor(Ui.CARD);
        previewBox.setPadding(Ui.dp(act, 14), Ui.dp(act, 10), Ui.dp(act, 14), Ui.dp(act, 10));
        LinearLayout.LayoutParams pbLp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        pbLp.topMargin = Ui.dp(act, 14);
        pbLp.bottomMargin = Ui.dp(act, 20);
        previewBox.setLayoutParams(pbLp);
        TextView pj = Ui.text(act, "O Senhor é o meu pastor, nada me faltará.", 16, Ui.TEXT, false);
        pj.setLineSpacing(Ui.dp(act, 3), 1f);
        previewBox.addView(pj);
        root.addView(previewBox);

        bar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override public void onProgressChanged(SeekBar sb, int progress, boolean fromUser) {
                value.setText(Ui.FONT_LEVEL_NAMES[progress]);
                if (fromUser) {
                    Ui.saveFontScale(act, Ui.FONT_LEVELS[progress]);
                    pj.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, Ui.FONT_LEVELS[progress] * 16f);
                }
            }

            @Override public void onStartTrackingTouch(SeekBar sb) {}

            @Override public void onStopTrackingTouch(SeekBar sb) {
                act.recreate();
            }
        });

        // divisor
        root.addView(Ui.vSpace(act, 6));

        root.addView(Ui.text(act, "Aparência", 15, Ui.TEXT, true));
        root.addView(Ui.vSpace(act, 4));

        for (int i = 0; i < Ui.THEME_NAMES.length; i++) {
            root.addView(themeRow(i));
        }

        root.addView(Ui.vSpace(act, 16));
        TextView note = Ui.text(act, "Seus destaques e músicas são mantidos entre as versões.", 13, Ui.MUTED, false);
        root.addView(note);

        view = root;
    }

    View view() {
        return view;
    }

    private View themeRow(final int mode) {
        LinearLayout row = Ui.row(act);
        row.setBackgroundColor(Ui.CARD);
        row.setPadding(Ui.dp(act, 14), Ui.dp(act, 12), Ui.dp(act, 14), Ui.dp(act, 12));
        row.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout.LayoutParams rp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        rp.bottomMargin = Ui.dp(act, 6);
        row.setLayoutParams(rp);

        TextView swatch = new TextView(act);
        GradientDrawable gd = new GradientDrawable();
        gd.setColor(Ui.accentForMode(mode));
        gd.setCornerRadius(Ui.dp(act, 9f));
        swatch.setBackground(gd);
        LinearLayout.LayoutParams sp = new LinearLayout.LayoutParams(Ui.dp(act, 18), Ui.dp(act, 18));
        sp.rightMargin = Ui.dp(act, 12);
        swatch.setLayoutParams(sp);
        row.addView(swatch);

        TextView name = Ui.text(act, Ui.THEME_NAMES[mode], 15, Ui.TEXT, false);
        row.addView(name, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));

        if (Ui.themeMode == mode) {
            row.addView(Ui.text(act, "✓", 18, Ui.ACCENT, true));
        }

        row.setOnClickListener(v -> {
            if (Ui.themeMode != mode) {
                Ui.saveTheme(act, mode);
                act.recreate();
            }
        });
        return row;
    }
}