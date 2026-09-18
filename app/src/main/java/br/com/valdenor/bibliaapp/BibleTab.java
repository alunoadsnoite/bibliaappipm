package br.com.valdenor.bibliaapp;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.InputMethodManager;
import android.widget.BaseAdapter;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.ScrollView;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.atomic.AtomicBoolean;

class BibleTab {

    private final Activity act;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private Runnable debounce;
    private final AtomicBoolean pending = new AtomicBoolean(false);
    private int jobId = 0;

    private final FrameLayout root;
    private final TextView backBtn;
    private final TextView title;
    private final TextView versionBtn;
    private final EditText search;
    private final FrameLayout body;

    private static final int MODE_BOOKS = 0;
    private static final int MODE_RESULTS = 1;
    private static final int MODE_CHAPTERS = 2;
    private static final int MODE_VERSES = 3;
    private int mode = MODE_BOOKS;
    private int curBookIndex = -1;
    private int curChapter = -1;

    static final class Result {
        final Data.Book book;
        final int chapter;
        final int verse;

        Result(Data.Book b, int c, int v) {
            book = b;
            chapter = c;
            verse = v;
        }
    }

    BibleTab(Activity a) {
        act = a;

        root = new FrameLayout(act);
        root.setBackgroundColor(Ui.BG);

        LinearLayout header = Ui.row(act);
        header.setPadding(Ui.dp(act, 8), Ui.dp(act, 8), Ui.dp(act, 12), Ui.dp(act, 8));
        header.setGravity(Gravity.CENTER_VERTICAL);

        backBtn = Ui.text(act, "‹", 30, Ui.PRIMARY, true);
        backBtn.setPadding(Ui.dp(act, 6), 0, Ui.dp(act, 10), 0);
        backBtn.setVisibility(View.GONE);
        header.addView(backBtn);

        title = Ui.text(act, "Bíblia", 18, Ui.TEXT, true);
        header.addView(title, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));

        versionBtn = Ui.text(act, currentVersionLabel(), 13, Ui.TEXT, true);
        versionBtn.setBackgroundColor(Ui.LIGHT);
        versionBtn.setPadding(Ui.dp(act, 8), Ui.dp(act, 5), Ui.dp(act, 8), Ui.dp(act, 5));
        LinearLayout.LayoutParams vp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        vp.rightMargin = Ui.dp(act, 8);
        versionBtn.setLayoutParams(vp);
        versionBtn.setOnClickListener(v -> showVersionDialog());
        header.addView(versionBtn);

        search = new EditText(act);
        search.setHint("Buscar (≥ 3 letras)");
        search.setTextSize(14 * Ui.FONT_SCALE);
        search.setSingleLine(true);
        search.setBackgroundColor(Ui.LIGHT);
        search.setPadding(Ui.dp(act, 10), Ui.dp(act, 8), Ui.dp(act, 10), Ui.dp(act, 8));
        header.addView(search, new LinearLayout.LayoutParams(Ui.dp(act, 150), LinearLayout.LayoutParams.WRAP_CONTENT));

        backBtn.setOnClickListener(v -> {
            search.setText("");
            showBooks();
        });

        body = new FrameLayout(act);

        LinearLayout col = Ui.column(act);
        col.addView(header);
        col.addView(body, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f));
        root.addView(col, new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        search.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence c, int s, int e, int a) {}
            @Override public void onTextChanged(CharSequence c, int s, int b, int e) {
                if (debounce != null) handler.removeCallbacks(debounce);
                debounce = () -> {
                    String q = c.toString().trim();
                    if (q.length() >= 3) {
                        globalSearch(q);
                    } else if (mode == MODE_RESULTS) {
                        search.setText("");
                        showBooks();
                    }
                };
                handler.postDelayed(debounce, 300);
            }
            @Override public void afterTextChanged(Editable c) {}
        });

        showBooks();
    }

    View view() {
        return root;
    }

    void onTabSelected() {
        if (search.getText().length() > 0) {
            search.requestFocus();
            InputMethodManager im = (InputMethodManager) act.getSystemService(Context.INPUT_METHOD_SERVICE);
            im.showSoftInput(search, InputMethodManager.SHOW_IMPLICIT);
        }
    }

    // ---------------------------------------------------------------- navegação

    private void setMode(int m, String t) {
        mode = m;
        title.setText(t);
        backBtn.setVisibility(m == MODE_BOOKS ? View.GONE : View.VISIBLE);
        hideKeyboard();
    }

    private void showBooks() {
        setMode(MODE_BOOKS, "Bíblia");
        clearBody();
        ScrollView sv = new ScrollView(act);
        LinearLayout col = Ui.column(act);
        col.setPadding(Ui.dp(act, 12), Ui.dp(act, 4), Ui.dp(act, 12), Ui.dp(act, 16));
        col.addView(Ui.header(act, "ANTIGO TESTAMENTO"));
        for (int i = 0; i < 39; i++) col.addView(makeBookItem(Data.bible.get(i), i));
        col.addView(Ui.header(act, "NOVO TESTAMENTO"));
        for (int i = 39; i < Data.bible.size(); i++) col.addView(makeBookItem(Data.bible.get(i), i));
        sv.addView(col);
        body.addView(sv, matchParent());
    }

    private View makeBookItem(final Data.Book b, final int idx) {
        LinearLayout item = Ui.row(act);
        item.setPadding(Ui.dp(act, 12), Ui.dp(act, 10), Ui.dp(act, 12), Ui.dp(act, 10));
        item.setBackgroundColor(Ui.CARD);
        item.setGravity(Gravity.CENTER_VERTICAL);
        item.setLayoutParams(itemParams());

        TextView num = Ui.text(act, String.valueOf(idx + 1), 13, Ui.MUTED, false);
        num.setGravity(Gravity.CENTER);
        num.setBackgroundColor(Ui.LIGHT);
        num.setPadding(Ui.dp(act, 4), Ui.dp(act, 4), Ui.dp(act, 4), Ui.dp(act, 4));
        item.addView(num);

        item.addView(Ui.hSpace(act, 12));

        item.addView(Ui.text(act, b.name, 16, Ui.TEXT, false),
                new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));

        item.addView(Ui.text(act, "›", 20, Ui.MUTED, true));

        item.setOnClickListener(v -> showChapters(b));
        return item;
    }

    private void showChapters(final Data.Book b) {
        curBookIndex = Data.bible.indexOf(b);
        setMode(MODE_CHAPTERS, b.name);
        clearBody();
        ScrollView sv = new ScrollView(act);
        LinearLayout col = Ui.column(act);
        col.setPadding(Ui.dp(act, 12), Ui.dp(act, 8), Ui.dp(act, 12), Ui.dp(act, 16));
        int n = b.chapters.size();
        col.addView(Ui.text(act, n + " capítulos", 13, Ui.MUTED, false));
        col.addView(Ui.vSpace(act, 4));
        int perRow = 6;
        int rows = (n + perRow - 1) / perRow;
        for (int r = 0; r < rows; r++) {
            LinearLayout row = Ui.row(act);
            for (int c = r * perRow; c < Math.min(n, (r + 1) * perRow); c++) {
                final int cc = c;
                TextView cell = Ui.text(act, String.valueOf(c + 1), 14, Ui.TEXT, false);
                cell.setGravity(Gravity.CENTER);
                cell.setBackgroundColor(Ui.CARD);
                cell.setPadding(0, Ui.dp(act, 13), 0, Ui.dp(act, 13));
                LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f);
                lp.leftMargin = Ui.dp(act, 3);
                lp.rightMargin = Ui.dp(act, 3);
                lp.topMargin = Ui.dp(act, 4);
                cell.setLayoutParams(lp);
                cell.setOnClickListener(v -> showVerses(b, cc));
                row.addView(cell);
            }
            col.addView(row);
        }
        sv.addView(col);
        body.addView(sv, matchParent());
    }

    private void showVerses(final Data.Book b, final int chapter) {
        curChapter = chapter;
        setMode(MODE_VERSES, b.name + " " + (chapter + 1));
        clearBody();
        ScrollView sv = new ScrollView(act);
        LinearLayout col = Ui.column(act);
        col.setPadding(Ui.dp(act, 4), Ui.dp(act, 4), Ui.dp(act, 4), Ui.dp(act, 16));

        List<String> vs = b.chapters.get(chapter);
        for (int v = 0; v < vs.size(); v++) {
            final String ref = b.abbr + " " + (chapter + 1) + ":" + (v + 1);
            LinearLayout row = Ui.column(act);
            row.setPadding(Ui.dp(act, 12), Ui.dp(act, 5), Ui.dp(act, 12), Ui.dp(act, 5));

            TextView refTv = Ui.text(act, ref, 12, Ui.ACCENT, true);
            TextView vTv = Ui.text(act, vs.get(v), 16, Ui.TEXT, false);
            vTv.setLineSpacing(Ui.dp(act, 3), 1f);

            row.addView(refTv);
            row.addView(vTv);
            applyHighlight(row, verdictKey(ref));
            row.setOnLongClickListener(vv -> {
                showVerseMenu(ref, row);
                return true;
            });
            col.addView(row);
        }
        sv.addView(col);
        body.addView(sv, matchParent());
        sv.post(() -> sv.scrollTo(0, 0));
    }

    // ---------------------------------------------------------------- versão

    private String currentVersionLabel() {
        int idx = 0;
        for (int i = 0; i < Data.VERSION_ORDER.length; i++) {
            if (Data.selectedVersion.equals(Data.VERSION_ORDER[i])) {
                idx = i;
                break;
            }
        }
        return Data.VERSION_ABBRS[idx] + " ▾";
    }

    private void showVersionDialog() {
        String[] display = new String[Data.VERSION_ORDER.length];
        int current = 0;
        for (int i = 0; i < Data.VERSION_ORDER.length; i++) {
            display[i] = Data.VERSION_ABBRS[i] + " — " + Data.VERSION_NAMES[i]
                    + (Data.selectedVersion.equals(Data.VERSION_ORDER[i]) ? "  ✓" : "");
            if (Data.selectedVersion.equals(Data.VERSION_ORDER[i])) current = i;
        }
        new AlertDialog.Builder(act)
                .setTitle("Versão da Bíblia")
                .setSingleChoiceItems(display, current, (d, w) -> {
                    Data.setVersion(act, Data.VERSION_ORDER[w]);
                    d.dismiss();
                    refreshCurrent();
                })
                .setPositiveButton("Fechar", null)
                .show();
    }

    private void refreshCurrent() {
        versionBtn.setText(currentVersionLabel());
        switch (mode) {
            case MODE_CHAPTERS:
                if (curBookIndex >= 0 && curBookIndex < Data.bible.size()) {
                    showChapters(Data.bible.get(curBookIndex));
                } else {
                    showBooks();
                }
                break;
            case MODE_VERSES:
                if (curBookIndex >= 0 && curBookIndex < Data.bible.size()
                        && curChapter >= 0 && curChapter < Data.bible.get(curBookIndex).chapters.size()) {
                    showVerses(Data.bible.get(curBookIndex), curChapter);
                } else {
                    showBooks();
                }
                break;
            default:
                showBooks();
                break;
        }
    }

    private LinearLayout.LayoutParams itemParams() {
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        lp.topMargin = Ui.dp(act, 5);
        return lp;
    }

    // ---------------------------------------------------------------- busca

    private void globalSearch(String q) {
        setMode(MODE_RESULTS, "Resultados");
        clearBody();
        LinearLayout loading = Ui.column(act);
        TextView l = Ui.text(act, "Buscando…", 15, Ui.MUTED, false);
        l.setGravity(Gravity.CENTER);
        loading.addView(l, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, Ui.dp(act, 80)));
        body.addView(loading);

        final String lower = q.toLowerCase(Locale.ROOT);
        final int myJob = ++jobId;
        new Thread(() -> {
            final List<Result> res = new ArrayList<>();
            int cap = 200;
            for (Data.Book b : Data.bible) {
                for (int c = 0; c < b.chapters.size(); c++) {
                    List<String> vs = b.chapters.get(c);
                    for (int v = 0; v < vs.size(); v++) {
                        if (vs.get(v).toLowerCase(Locale.ROOT).contains(lower)) {
                            res.add(new Result(b, c, v));
                            if (res.size() >= cap) break;
                        }
                    }
                    if (res.size() >= cap) break;
                }
                if (res.size() >= cap) break;
            }
            handler.post(() -> {
                if (myJob == jobId) showResults(res, lower);
            });
        }).start();
    }

    private void showResults(List<Result> res, String lower) {
        if (mode != MODE_RESULTS) return;
        clearBody();
        ListView lv = new ListView(act);
        lv.setDivider(null);
        lv.setBackgroundColor(Ui.BG);
        lv.setAdapter(new BaseAdapter() {
            @Override public int getCount() {
                return res.size();
            }

            @Override public Object getItem(int i) {
                return res.get(i);
            }

            @Override public long getItemId(int i) {
                return i;
            }

            @Override public View getView(int i, View convertView, ViewGroup parent) {
                Result r = res.get(i);
                LinearLayout item = Ui.column(act);
                item.setPadding(Ui.dp(act, 12), Ui.dp(act, 8), Ui.dp(act, 12), Ui.dp(act, 8));
                item.setBackgroundColor(Ui.CARD);
                item.addView(Ui.text(act, r.book.abbr + " " + (r.chapter + 1) + ":" + (r.verse + 1), 12, Ui.ACCENT, true));
                item.addView(Ui.text(act, r.book.chapters.get(r.chapter).get(r.verse), 15, Ui.TEXT, false));
                item.setOnClickListener(v -> {
                    search.setText("");
                    curBookIndex = Data.bible.indexOf(r.book);
                    curChapter = r.chapter;
                    showVerses(r.book, r.chapter);
                });
                LinearLayout.LayoutParams lp = itemParams();
                lp.leftMargin = Ui.dp(act, 8);
                lp.rightMargin = Ui.dp(act, 8);
                item.setLayoutParams(lp);
                return item;
            }
        });
        body.addView(lv, matchParent());
        if (res.isEmpty()) {
            TextView empty = Ui.text(act, "Nenhum resultado para \"" + lower + "\"", 15, Ui.MUTED, false);
            empty.setGravity(Gravity.CENTER);
            empty.setPadding(0, Ui.dp(act, 40), 0, 0);
            body.addView(empty, new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT));
        }
    }

    // ---------------------------------------------------------------- destaque

    private static String verdictKey(String ref) {
        return "v:" + ref;
    }

    private void applyHighlight(LinearLayout row, String key) {
        int ci = Highlights.get(act, key);
        if (ci >= 0 && ci < Highlights.COLORS.length) {
            row.setBackgroundColor(Color.parseColor(Highlights.COLORS[ci]));
        } else {
            row.setBackgroundColor(Color.TRANSPARENT);
        }
    }

    private void showVerseMenu(final String ref, final LinearLayout row) {
        final String key = verdictKey(ref);
        int ci = Highlights.get(act, key);
        String[] items = new String[8];
        items[0] = "Copiar versículo";
        items[1] = "Compartilhar";
        for (int i = 0; i < 6; i++) {
            items[i + 2] = "Destaque " + Highlights.COLOR_NAMES[i] + (ci == i ? " ✓" : "");
        }
        new AlertDialog.Builder(act)
                .setTitle(ref)
                .setItems(items, (d, w) -> {
                    if (w == 0) copy(ref);
                    else if (w == 1) share(ref);
                    else {
                        Highlights.set(act, key, w - 2);
                        applyHighlight(row, key);
                    }
                })
                .setNegativeButton("Cancelar", null)
                .show();
    }

    private void copy(String text) {
        ClipboardManager cm = (ClipboardManager) act.getSystemService(Context.CLIPBOARD_SERVICE);
        cm.setPrimaryClip(ClipData.newPlainText("texto", text));
    }

    private void share(String text) {
        Intent i = new Intent(Intent.ACTION_SEND);
        i.setType("text/plain");
        i.putExtra(Intent.EXTRA_TEXT, text);
        act.startActivity(Intent.createChooser(i, "Compartilhar"));
    }

    private void hideKeyboard() {
        InputMethodManager im = (InputMethodManager) act.getSystemService(Context.INPUT_METHOD_SERVICE);
        im.hideSoftInputFromWindow(search.getWindowToken(), 0);
    }

    private void clearBody() {
        body.removeAllViews();
    }

    private FrameLayout.LayoutParams matchParent() {
        return new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT);
    }
}