package br.com.valdenor.bibliaapp;

import android.app.Activity;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.Window;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;

public class MainActivity extends Activity {

    private FrameLayout content;
    private LinearLayout bottomBar;
    private final LinearLayout[] tabViews = new LinearLayout[5];
    private int currentTab = -1;
    private BibleTab bibleTab;
    private HymnsTab hymnsTab;
    private SongsTab songsTab;
    private BoletimTab boletimTab;
    private SettingsTab settingsTab;

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        Ui.init(getApplicationContext());

        Window win = getWindow();
        win.setStatusBarColor(Ui.PRIMARY_DARK);
        win.setNavigationBarColor(Ui.PRIMARY_DARK);
        win.getDecorView().setBackgroundColor(Ui.BG);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);

        content = new FrameLayout(this);
        root.addView(content, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f));

        bottomBar = new LinearLayout(this);
        bottomBar.setOrientation(LinearLayout.HORIZONTAL);
        bottomBar.setBackgroundColor(Ui.PRIMARY_DARK);
        root.addView(bottomBar, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, Ui.dp(this, 62)));

        setContentView(root);

        buildTab(0, "📖", "Bíblia");
        buildTab(1, "🎵", "Hinário");
        buildTab(2, "⭐", "Músicas");
        buildTab(3, "🗓", "Boletim");
        buildTab(4, "⚙️", "Config");

        FrameLayout txt = new FrameLayout(this);
        TextView loading = Ui.text(this, "Carregando conteúdo…", 15, Ui.MUTED, false);
        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT);
        lp.gravity = Gravity.CENTER;
        txt.addView(loading, lp);
        content.addView(txt);

        new Thread(() -> {
            try {
                Data.load(getApplicationContext());
                runOnUiThread(this::buildTabs);
            } catch (final Throwable t) {
                runOnUiThread(() -> showLoadError(t));
            }
        }).start();
    }

    private void showLoadError(Throwable t) {
        content.removeAllViews();
        LinearLayout box = new LinearLayout(this);
        box.setOrientation(LinearLayout.VERTICAL);
        box.setGravity(Gravity.CENTER);
        box.setPadding(Ui.dp(this, 24), 0, Ui.dp(this, 24), 0);

        TextView msg = Ui.text(this, "Não foi possível carregar os conteúdos.\n\n"
                + (t.getMessage() != null ? t.getMessage() : t.getClass().getSimpleName())
                + "\n\nTente novamente.", 14, Ui.TEXT, false);
        msg.setGravity(Gravity.CENTER);
        box.addView(msg);

        TextView retry = Ui.text(this, "↻ Tentar de novo", 15, android.graphics.Color.WHITE, true);
        retry.setGravity(Gravity.CENTER);
        retry.setBackgroundColor(Ui.ACCENT);
        retry.setPadding(Ui.dp(this, 24), Ui.dp(this, 10), Ui.dp(this, 24), Ui.dp(this, 10));
        LinearLayout.LayoutParams rl = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        rl.topMargin = Ui.dp(this, 20);
        retry.setLayoutParams(rl);
        retry.setOnClickListener(v -> {
            content.removeAllViews();
            TextView loading = Ui.text(this, "Carregando conteúdo…", 15, Ui.MUTED, false);
            FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT);
            lp.gravity = Gravity.CENTER;
            content.addView(loading, lp);
            new Thread(() -> {
                try {
                    Data.load(getApplicationContext());
                    runOnUiThread(MainActivity.this::buildTabs);
                } catch (final Throwable t2) {
                    runOnUiThread(() -> showLoadError(t2));
                }
            }).start();
        });
        box.addView(retry);

        content.addView(box);
    }

    private void buildTabs() {
        content.removeAllViews();
        bibleTab = new BibleTab(this);
        hymnsTab = new HymnsTab(this);
        songsTab = new SongsTab(this);
        boletimTab = new BoletimTab(this);
        settingsTab = new SettingsTab(this);
        content.addView(bibleTab.view(), new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
        content.addView(hymnsTab.view(), new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
        content.addView(songsTab.view(), new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
        content.addView(boletimTab.view(), new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
        content.addView(settingsTab.view(), new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
        select(0);
    }

    private void buildTab(int index, String icon, String label) {
        LinearLayout tab = new LinearLayout(this);
        tab.setOrientation(LinearLayout.VERTICAL);
        tab.setGravity(Gravity.CENTER);
        tab.setClickable(true);

        TextView ic = Ui.text(this, icon, 20, android.graphics.Color.WHITE, false);
        TextView lb = Ui.text(this, label, 11, android.graphics.Color.WHITE, false);
        tab.addView(ic);
        tab.addView(lb);

        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f);
        tab.setLayoutParams(lp);

        final int fi = index;
        tab.setOnClickListener(v -> select(fi));
        bottomBar.addView(tab);
        tabViews[index] = tab;
    }

    private void select(int index) {
        if (index == currentTab) return;
        currentTab = index;
        boolean select = false;
        for (int i = 0; i < tabViews.length; i++) {
            tabViews[i].setBackgroundColor(i == index ? Ui.TAB_SELECTED : Ui.PRIMARY_DARK);
            if (i == index) select = true;
        }
        boolean b = index == 0, h = index == 1, s = index == 2, k = index == 3, g = index == 4;
        if (bibleTab != null) bibleTab.view().setVisibility(b ? View.VISIBLE : View.GONE);
        if (hymnsTab != null) hymnsTab.view().setVisibility(h ? View.VISIBLE : View.GONE);
        if (songsTab != null) songsTab.view().setVisibility(s ? View.VISIBLE : View.GONE);
        if (boletimTab != null) boletimTab.view().setVisibility(k ? View.VISIBLE : View.GONE);
        if (settingsTab != null) settingsTab.view().setVisibility(g ? View.VISIBLE : View.GONE);
        if (b && bibleTab != null) bibleTab.onTabSelected();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (bibleTab != null) {
            getWindow().setStatusBarColor(Ui.PRIMARY_DARK);
            getWindow().setNavigationBarColor(Ui.PRIMARY_DARK);
        }
    }
}