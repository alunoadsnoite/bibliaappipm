package br.com.valdenor.bibliaapp;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.text.InputType;
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

class SongsTab {

    private final Activity act;
    private final FrameLayout root;
    private final TextView backBtn;
    private final TextView title;
    private final TextView addBtn;
    private final FrameLayout body;
    private final ListView list;

    private int curSongIndex = -1;

    SongsTab(Activity a) {
        act = a;

        root = new FrameLayout(act);
        root.setBackgroundColor(Ui.BG);

        LinearLayout header = Ui.row(act);
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

        title = Ui.text(act, "Músicas", 18, Ui.TEXT, true);
        header.addView(title, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));

        addBtn = Ui.text(act, "＋ Adicionar", 14, Ui.ACCENT, true);
        addBtn.setPadding(Ui.dp(act, 8), Ui.dp(act, 6), Ui.dp(act, 4), Ui.dp(act, 6));
        addBtn.setOnClickListener(v -> showAddEditDialog(-1));
        addBtn.setVisibility(View.GONE);
        header.addView(addBtn);

        body = new FrameLayout(act);

        LinearLayout col = Ui.column(act);
        col.addView(header);
        col.addView(body, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f));
        root.addView(col, new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        list = new ListView(act);
        list.setDivider(null);
        list.setBackgroundColor(Ui.BG);

        showList();
    }

    View view() {
        return root;
    }

    private void showList() {
        backBtn.setVisibility(View.GONE);
        addBtn.setVisibility(View.GONE);
        title.setText("Músicas");
        curSongIndex = -1;
        body.removeAllViews();
        list.setAdapter(new SongAdapter());
        body.addView(list, new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
        if (Data.songs.isEmpty()) {
            TextView empty = Ui.text(act, "Nenhuma música adicionada.\nToque em ＋ Adicionar para incluir letras.", 14, Ui.MUTED, false);
            empty.setGravity(Gravity.CENTER);
            empty.setPadding(Ui.dp(act, 20), Ui.dp(act, 40), Ui.dp(act, 20), 0);
            body.addView(empty, new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT));
        } else {
            addBtn.setVisibility(View.VISIBLE);
        }
    }

    private void showDetail(int index) {
        curSongIndex = index;
        Data.Song s = Data.songs.get(index);
        hideKeyboard();
        backBtn.setVisibility(View.VISIBLE);
        addBtn.setVisibility(View.VISIBLE);
        title.setText(s.title);
        body.removeAllViews();

        ScrollView sv = new ScrollView(act);
        LinearLayout col = Ui.column(act);
        col.setPadding(Ui.dp(act, 16), Ui.dp(act, 8), Ui.dp(act, 16), Ui.dp(act, 24));
        col.setBackgroundColor(Ui.CARD);

        TextView titleTv = Ui.text(act, s.title, 22, Ui.TEXT, true);
        titleTv.setGravity(Gravity.CENTER_HORIZONTAL);
        col.addView(titleTv, matchWrap());
        col.addView(Ui.vSpace(act, 10));

        String[] linesArr = s.lyrics.split("\n");
        for (int li = 0; li < linesArr.length; li++) {
            if (linesArr[li].trim().isEmpty()) {
                col.addView(Ui.vSpace(act, 6));
                continue;
            }
            final String key = "s:" + index + ":" + li;
            final String lineText = linesArr[li];
            TextView line = new TextView(act);
            line.setText(lineText);
            line.setTextSize(16 * Ui.FONT_SCALE);
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
        sv.addView(col);
        body.addView(sv, new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
        sv.post(() -> sv.scrollTo(0, 0));
    }

    private void showAddEditDialog(final int index) {
        LinearLayout box = Ui.column(act);
        box.setPadding(Ui.dp(act, 20), Ui.dp(act, 4), Ui.dp(act, 20), Ui.dp(act, 4));

        final EditText eTitle = new EditText(act);
        eTitle.setHint("Título da música");
        eTitle.setTextSize(16 * Ui.FONT_SCALE);
        box.addView(eTitle);
        box.addView(Ui.vSpace(act, 10));

        final EditText eLyrics = new EditText(act);
        eLyrics.setHint("Letra (uma frase por linha)");
        eLyrics.setTextSize(15 * Ui.FONT_SCALE);
        eLyrics.setGravity(Gravity.TOP | Gravity.START);
        eLyrics.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_CAP_SENTENCES | InputType.TYPE_TEXT_FLAG_MULTI_LINE);
        eLyrics.setMinLines(8);
        eLyrics.setBackgroundColor(Ui.LIGHT);
        eLyrics.setPadding(Ui.dp(act, 8), Ui.dp(act, 8), Ui.dp(act, 8), Ui.dp(act, 8));
        box.addView(eLyrics);

        if (index >= 0) {
            Data.Song s = Data.songs.get(index);
            eTitle.setText(s.title);
            eLyrics.setText(s.lyrics);
        }

        new AlertDialog.Builder(act)
                .setTitle(index >= 0 ? "Editar música" : "Nova música")
                .setView(box)
                .setPositiveButton("Salvar", (d, w) -> {
                    String t = eTitle.getText().toString().trim();
                    String l = eLyrics.getText().toString().trim();
                    if (t.isEmpty() || l.isEmpty()) return;
                    if (index >= 0) {
                        Data.songs.get(index).title = t;
                        Data.songs.get(index).lyrics = l;
                    } else {
                        Data.Song s = new Data.Song();
                        s.title = t;
                        s.lyrics = l;
                        Data.songs.add(s);
                    }
                    Data.saveSongs(act);
                    showList();
                })
                .setNegativeButton("Cancelar", null)
                .show();
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
        im.hideSoftInputFromWindow(root.getWindowToken(), 0);
    }

    private LinearLayout.LayoutParams matchWrap() {
        return new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
    }

    private class SongAdapter extends BaseAdapter {
        @Override public int getCount() {
            return Data.songs.size();
        }

        @Override public Object getItem(int i) {
            return Data.songs.get(i);
        }

        @Override public long getItemId(int i) {
            return i;
        }

        @Override public View getView(final int i, View convertView, ViewGroup parent) {
            Data.Song s = Data.songs.get(i);
            LinearLayout item = Ui.column(act);
            item.setBackgroundColor(Ui.CARD);
            item.setPadding(Ui.dp(act, 14), Ui.dp(act, 10), Ui.dp(act, 14), Ui.dp(act, 10));
            item.addView(Ui.text(act, s.title, 16, Ui.TEXT, true));
            String preview = s.lyrics.trim();
            if (preview.isEmpty()) {
                preview = "";
            } else {
                int nl = preview.indexOf('\n');
                if (nl >= 0) preview = preview.substring(0, nl);
                if (preview.length() > 70) preview = preview.substring(0, 70) + "…";
            }
            item.addView(Ui.text(act, preview, 13, Ui.MUTED, false));

            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
            lp.topMargin = Ui.dp(act, 5);
            lp.leftMargin = Ui.dp(act, 8);
            lp.rightMargin = Ui.dp(act, 8);
            item.setLayoutParams(lp);

            item.setOnClickListener(v -> showDetail(i));
            item.setOnLongClickListener(v -> {
                showItemMenu(i);
                return true;
            });
            return item;
        }
    }

    private void showItemMenu(final int index) {
        new AlertDialog.Builder(act)
                .setTitle(Data.songs.get(index).title)
                .setItems(new String[]{"Abrir", "Editar", "Excluir", "Compartilhar"}, (d, w) -> {
                    if (w == 0) showDetail(index);
                    else if (w == 1) showAddEditDialog(index);
                    else if (w == 2) {
                        Data.songs.remove(index);
                        Data.saveSongs(act);
                        showList();
                    } else {
                        share(Data.songs.get(index).title + "\n\n" + Data.songs.get(index).lyrics);
                    }
                })
                .setNegativeButton("Cancelar", null)
                .show();
    }
}