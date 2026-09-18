package br.com.valdenor.bibliaapp;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
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

class HymnsTab {

    private final Activity act;
    private final FrameLayout root;
    private final LinearLayout header;
    private final TextView backBtn;
    private final TextView title;
    private final EditText search;
    private final FrameLayout body;
    private final ListView list;
    private final List<Data.Hymn> all = new ArrayList<>();
    private final List<Data.Hymn> filtered = new ArrayList<>();

    private Data.Hymn curHymn;

    HymnsTab(Activity a) {
        act = a;
        all.addAll(Data.hymns);
        filtered.addAll(all);

        root = new FrameLayout(act);
        root.setBackgroundColor(Ui.BG);

        header = Ui.row(act);
        header.setPadding(Ui.dp(act, 8), Ui.dp(act, 8), Ui.dp(act, 12), Ui.dp(act, 8));
        header.setGravity(Gravity.CENTER_VERTICAL);

        backBtn = Ui.text(act, "‹", 30, Ui.PRIMARY, true);
        backBtn.setPadding(Ui.dp(act, 6), 0, Ui.dp(act, 10), 0);
        backBtn.setVisibility(View.GONE);
        backBtn.setOnClickListener(v -> {
            hideKeyboard();
            showList();
        });
        header.addView(backBtn);

        title = Ui.text(act, "Hinário Novo Cântico", 18, Ui.TEXT, true);
        header.addView(title, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));

        search = new EditText(act);
        search.setHint("Buscar hino");
        search.setTextSize(14 * Ui.FONT_SCALE);
        search.setSingleLine(true);
        search.setBackgroundColor(Ui.LIGHT);
        search.setPadding(Ui.dp(act, 10), Ui.dp(act, 8), Ui.dp(act, 10), Ui.dp(act, 8));
        header.addView(search, new LinearLayout.LayoutParams(Ui.dp(act, 130), LinearLayout.LayoutParams.WRAP_CONTENT));

        body = new FrameLayout(act);

        LinearLayout col = Ui.column(act);
        col.addView(header);
        col.addView(body, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f));
        root.addView(col, new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        list = new ListView(act);
        list.setDivider(null);
        list.setBackgroundColor(Ui.BG);
        list.setAdapter(new HymnAdapter());

        search.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence c, int s, int e, int a) {}
            @Override public void onTextChanged(CharSequence c, int s, int b, int e) {
                filter(c.toString());
            }
            @Override public void afterTextChanged(Editable c) {}
        });

        showList();
    }

    View view() {
        return root;
    }

    private void filter(String q) {
        filtered.clear();
        String lower = q.trim().toLowerCase(Locale.ROOT);
        if (lower.isEmpty()) {
            filtered.addAll(all);
        } else {
            for (Data.Hymn h : all) {
                if (h.searchText().contains(lower)) filtered.add(h);
            }
        }
        list.setAdapter(new HymnAdapter());
    }

    private void showList() {
        header.setVisibility(View.VISIBLE);
        backBtn.setVisibility(View.GONE);
        title.setText("Hinário Novo Cântico");
        search.setVisibility(View.VISIBLE);
        body.removeAllViews();
        body.addView(list, new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
        list.setAdapter(new HymnAdapter());
    }

    private void showDetail(final Data.Hymn h) {
        curHymn = h;
        hideKeyboard();
        backBtn.setVisibility(View.VISIBLE);
        title.setText(h.num + " - " + h.title);
        search.setVisibility(View.GONE);
        header.setVisibility(View.VISIBLE);
        body.removeAllViews();

        ScrollView sv = new ScrollView(act);
        LinearLayout col = Ui.column(act);
        col.setPadding(Ui.dp(act, 16), Ui.dp(act, 8), Ui.dp(act, 16), Ui.dp(act, 24));
        col.setBackgroundColor(Ui.CARD);

        TextView titleTv = Ui.text(act, h.title, 22, Ui.TEXT, true);
        titleTv.setGravity(Gravity.CENTER_HORIZONTAL);
        col.addView(titleTv, matchWrap());

        if (h.author != null && !h.author.isEmpty()) {
            TextView auth = Ui.text(act, h.author, 13, Ui.MUTED, false);
            auth.setGravity(Gravity.CENTER_HORIZONTAL);
            auth.setPadding(0, Ui.dp(act, 2), 0, 0);
            col.addView(auth, matchWrap());
        }
        col.addView(Ui.vSpace(act, 8));

        for (int s = 0; s < h.stanzas.size(); s++) {
            String label = stanzaLabel(h.stanzaNames.get(s));
            if (!label.isEmpty()) {
                TextView lbl = Ui.text(act, label, 14, Ui.ACCENT, true);
                lbl.setGravity(Gravity.CENTER_HORIZONTAL);
                lbl.setPadding(0, Ui.dp(act, 14), 0, Ui.dp(act, 2));
                col.addView(lbl, matchWrap());
            } else {
                col.addView(Ui.vSpace(act, 10));
            }
            List<String> lines = h.stanzas.get(s);
            for (int li = 0; li < lines.size(); li++) {
                final String key = "h:" + h.num + ":" + s + ":" + li;
                final String lineText = lines.get(li);
                TextView line = new TextView(act);
                line.setText(lineText);
                line.setTextSize(16);
                line.setTextColor(Ui.TEXT);
                line.setLineSpacing(Ui.dp(act, 3), 1f);
                line.setGravity(Gravity.CENTER_HORIZONTAL);
                line.setPadding(0, Ui.dp(act, 3), 0, Ui.dp(act, 3));
                applyLineHighlight(line, key);
                line.setOnLongClickListener(v -> {
                    showLineMenu(line, key, lineText);
                    return true;
                });
                col.addView(line, matchWrap());
            }
        }
        sv.addView(col);
        body.addView(sv, new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
        sv.post(() -> sv.scrollTo(0, 0));
    }

    private static String stanzaLabel(String name) {
        if (name == null || name.isEmpty()) return "";
        char c = name.charAt(0);
        switch (c) {
            case 'c': return "CORO";
            case 'b': return "PONTE";
            case 'p': return "PRELÚDIO";
            case 'o': return "OUTRO";
            case 'e': return name.toUpperCase(Locale.ROOT);
            default: return "";
        }
    }

    private void applyLineHighlight(TextView line, String key) {
        int ci = Highlights.get(act, key);
        line.setBackgroundColor(ci >= 0 && ci < Highlights.COLORS.length
                ? Color.parseColor(Highlights.COLORS[ci]) : Color.TRANSPARENT);
    }

    private void showLineMenu(final TextView line, final String key, String text) {
        int ci = Highlights.get(act, key);
        String[] items = new String[8];
        items[0] = "Copiar";
        items[1] = "Compartilhar";
        for (int i = 0; i < 6; i++) {
            items[i + 2] = "Destaque " + Highlights.COLOR_NAMES[i] + (ci == i ? " ✓" : "");
        }
        new AlertDialog.Builder(act)
                .setTitle(text.length() > 40 ? text.substring(0, 40) + "…" : text)
                .setItems(items, (d, w) -> {
                    if (w == 0) copy(text);
                    else if (w == 1) share(text);
                    else {
                        Highlights.set(act, key, w - 2);
                        applyLineHighlight(line, key);
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

    private LinearLayout.LayoutParams matchWrap() {
        return new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
    }

    private class HymnAdapter extends BaseAdapter {
        @Override public int getCount() {
            return filtered.size();
        }

        @Override public Object getItem(int i) {
            return filtered.get(i);
        }

        @Override public long getItemId(int i) {
            return filtered.get(i).num;
        }

        @Override public View getView(int i, View convertView, ViewGroup parent) {
            Data.Hymn h = filtered.get(i);
            LinearLayout item = Ui.column(act);
            item.setBackgroundColor(Ui.CARD);
            item.setPadding(Ui.dp(act, 14), Ui.dp(act, 10), Ui.dp(act, 14), Ui.dp(act, 10));
            TextView num = Ui.text(act, String.valueOf(h.num), 12, Ui.ACCENT, true);
            item.addView(num);
            item.addView(Ui.text(act, h.title, 16, Ui.TEXT, false));
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
            lp.topMargin = Ui.dp(act, 5);
            lp.leftMargin = Ui.dp(act, 8);
            lp.rightMargin = Ui.dp(act, 8);
            item.setLayoutParams(lp);
            item.setOnClickListener(v -> showDetail(h));
            return item;
        }
    }
}