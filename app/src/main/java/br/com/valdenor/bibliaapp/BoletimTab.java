package br.com.valdenor.bibliaapp;

import android.app.Activity;
import android.app.AlertDialog;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.List;
import java.util.Locale;

class BoletimTab {

    private final Activity act;
    private final FrameLayout root;
    private final TextView backBtn;
    private final TextView title;
    private final TextView editBtn;
    private final FrameLayout body;

    private boolean editing = false;

    BoletimTab(Activity a) {
        act = a;

        root = new FrameLayout(act);
        root.setBackgroundColor(Ui.BG);

        LinearLayout header = Ui.row(act);
        header.setPadding(Ui.dp(act, 8), Ui.dp(act, 8), Ui.dp(act, 12), Ui.dp(act, 8));
        header.setGravity(Gravity.CENTER_VERTICAL);

        backBtn = Ui.text(act, "‹", 30, Ui.PRIMARY, true);
        backBtn.setPadding(Ui.dp(act, 6), 0, Ui.dp(act, 10), 0);
        backBtn.setVisibility(View.GONE);
        backBtn.setOnClickListener(v -> setEditing(false));
        header.addView(backBtn);

        title = Ui.text(act, "Boletim", 18, Ui.TEXT, true);
        header.addView(title, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));

        editBtn = Ui.text(act, "✎ Editar", 14, Ui.ACCENT, true);
        editBtn.setPadding(Ui.dp(act, 8), Ui.dp(act, 6), Ui.dp(act, 4), Ui.dp(act, 6));
        editBtn.setOnClickListener(v -> setEditing(!editing));
        header.addView(editBtn);

        body = new FrameLayout(act);

        LinearLayout col = Ui.column(act);
        col.addView(header);
        col.addView(body, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f));
        root.addView(col, new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        showView();
    }

    View view() {
        return root;
    }

    private void setEditing(boolean e) {
        editing = e;
        backBtn.setVisibility(e ? View.VISIBLE : View.GONE);
        editBtn.setText(e ? "✓ Concluir" : "✎ Editar");
        showView();
    }

    private void showView() {
        body.removeAllViews();
        ScrollView sv = new ScrollView(act);
        LinearLayout col = Ui.column(act);
        col.setPadding(Ui.dp(act, 12), Ui.dp(act, 4), Ui.dp(act, 12), Ui.dp(act, 20));

        if (editing) {
            buildEditView(col);
        } else {
            buildMainView(col);
        }

        sv.addView(col);
        body.addView(sv, new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
        sv.post(() -> sv.scrollTo(0, 0));
    }

    private void buildMainView(LinearLayout col) {
        col.addView(Ui.header(act, "🎂 ANIVERSARIANTES DO DIA"));

        List<Data.Birthday> today = birthdaysToday();
        if (today.isEmpty()) {
            col.addView(none("Nenhum aniversariante hoje."));
        } else {
            for (Data.Birthday b : today) {
                LinearLayout item = card();
                item.addView(Ui.text(act, b.name, 16, Ui.TEXT, false));
                col.addView(item);
            }
        }

        col.addView(Ui.vSpace(act, 8));
        col.addView(Ui.header(act, "📅 PRÓXIMOS EVENTOS"));

        List<Data.Event> upcoming = upcomingEvents();
        if (upcoming.isEmpty()) {
            col.addView(none("Nenhum evento agendado."));
        } else {
            for (Data.Event e : upcoming) {
                LinearLayout item = card();
                item.addView(Ui.text(act, e.title, 16, Ui.TEXT, true));
                StringBuilder sub = new StringBuilder(formatEventDate(e));
                if (e.time != null && !e.time.isEmpty()) sub.append("  às ").append(e.time);
                if (e.note != null && !e.note.isEmpty()) sub.append("  ·  ").append(e.note);
                item.addView(Ui.text(act, sub.toString(), 13, Ui.MUTED, false));
                col.addView(item);
            }
        }
    }

    private void buildEditView(LinearLayout col) {
        col.addView(sectionHeader(1, "Aniversariantes", "＋"));
        if (Data.birthdays.isEmpty()) {
            col.addView(none("Nenhum aniversariante cadastrado."));
        } else {
            for (int i = 0; i < Data.birthdays.size(); i++) {
                final int idx = i;
                Data.Birthday b = Data.birthdays.get(i);
                LinearLayout item = card();
                item.addView(Ui.text(act, b.name, 16, Ui.TEXT, false));
                item.addView(Ui.text(act, formatBirthdayDate(b), 13, Ui.MUTED, false));
                item.setOnClickListener(v -> birthdayDialog(idx));
                item.setOnLongClickListener(v -> {
                    birthdayMenu(idx);
                    return true;
                });
                col.addView(item);
            }
        }

        col.addView(Ui.vSpace(act, 8));
        col.addView(sectionHeader(2, "Eventos", "＋"));
        if (Data.events.isEmpty()) {
            col.addView(none("Nenhum evento cadastrado."));
        } else {
            for (int i = 0; i < Data.events.size(); i++) {
                final int idx = i;
                Data.Event e = Data.events.get(i);
                LinearLayout item = card();
                item.addView(Ui.text(act, e.title, 16, Ui.TEXT, false));
                item.addView(Ui.text(act, formatEventDate(e) + (e.time != null && !e.time.isEmpty() ? "  às " + e.time : ""), 13, Ui.MUTED, false));
                item.setOnClickListener(v -> eventDialog(idx));
                item.setOnLongClickListener(v -> {
                    eventMenu(idx);
                    return true;
                });
                col.addView(item);
            }
        }

        col.addView(Ui.vSpace(act, 10));
        TextView tip = Ui.text(act, "Toque para editar e segure para abrir o menu. Os aniversariantes aparecem automaticamente no dia, e os eventos com data passada deixam de ser exibidos.", 12, Ui.MUTED, false);
        tip.setPadding(Ui.dp(act, 16), Ui.dp(act, 4), Ui.dp(act, 16), Ui.dp(act, 4));
        col.addView(tip);
    }

    private LinearLayout sectionHeader(final int which, String label, String addLabel) {
        LinearLayout row = Ui.row(act);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(Ui.dp(act, 16), Ui.dp(act, 10), Ui.dp(act, 16), Ui.dp(act, 2));
        row.addView(Ui.text(act, label, 15, Ui.TEXT, true),
                new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));
        TextView add = Ui.text(act, addLabel, 22, Ui.ACCENT, true);
        add.setPadding(Ui.dp(act, 10), Ui.dp(act, 0), Ui.dp(act, 10), Ui.dp(act, 0));
        add.setOnClickListener(v -> {
            if (which == 1) birthdayDialog(-1);
            else eventDialog(-1);
        });
        row.addView(add);
        return row;
    }

    private void birthdayDialog(final int index) {
        LinearLayout box = Ui.column(act);
        box.setPadding(Ui.dp(act, 20), Ui.dp(act, 4), Ui.dp(act, 20), Ui.dp(act, 4));

        final EditText eName = field("Nome", false);
        box.addView(eName);

        LinearLayout dm = Ui.row(act);
        final EditText eDay = field("Dia", true);
        dm.addView(eDay, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));
        dm.addView(Ui.hSpace(act, 8));
        final EditText eMonth = field("Mês", true);
        dm.addView(eMonth, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));
        box.addView(dm);

        if (index >= 0) {
            Data.Birthday b = Data.birthdays.get(index);
            eName.setText(b.name);
            eDay.setText(String.valueOf(b.day));
            eMonth.setText(String.valueOf(b.month));
        }

        new AlertDialog.Builder(act)
                .setTitle(index >= 0 ? "Editar aniversariante" : "Novo aniversariante")
                .setView(box)
                .setPositiveButton("Salvar", (d, w) -> {
                    String name = eName.getText().toString().trim();
                    int day = parseInt(eDay);
                    int month = parseInt(eMonth);
                    if (name.isEmpty() || day < 1 || day > 31 || month < 1 || month > 12) return;
                    if (index >= 0) {
                        Data.birthdays.get(index).name = name;
                        Data.birthdays.get(index).day = day;
                        Data.birthdays.get(index).month = month;
                    } else {
                        Data.Birthday b = new Data.Birthday();
                        b.name = name;
                        b.day = day;
                        b.month = month;
                        Data.birthdays.add(b);
                    }
                    Data.saveBoletim(act);
                    showView();
                })
                .setNegativeButton("Cancelar", null)
                .show();
    }

    private void eventDialog(final int index) {
        LinearLayout box = Ui.column(act);
        box.setPadding(Ui.dp(act, 20), Ui.dp(act, 4), Ui.dp(act, 20), Ui.dp(act, 4));

        final EditText eTitle = field("Título do evento", false);
        box.addView(eTitle);

        LinearLayout ymd = Ui.row(act);
        final EditText eDay = field("Dia", true);
        ymd.addView(eDay, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));
        ymd.addView(Ui.hSpace(act, 8));
        final EditText eMonth = field("Mês", true);
        ymd.addView(eMonth, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));
        ymd.addView(Ui.hSpace(act, 8));
        final EditText eYear = field("Ano", true);
        ymd.addView(eYear, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));
        box.addView(ymd);

        LinearLayout ho = Ui.row(act);
        final EditText eTime = field("Hora (opcional)", false);
        ho.addView(eTime, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));
        box.addView(ho);

        final EditText eNote = field("Observação (opcional)", false);
        box.addView(eNote);

        if (index >= 0) {
            Data.Event e = Data.events.get(index);
            eTitle.setText(e.title);
            eDay.setText(String.valueOf(e.day));
            eMonth.setText(String.valueOf(e.month));
            eYear.setText(String.valueOf(e.year));
            eTime.setText(e.time);
            eNote.setText(e.note);
        } else {
            eYear.setText(String.valueOf(Calendar.getInstance().get(Calendar.YEAR)));
        }

        new AlertDialog.Builder(act)
                .setTitle(index >= 0 ? "Editar evento" : "Novo evento")
                .setView(box)
                .setPositiveButton("Salvar", (d, w) -> {
                    String titleText = eTitle.getText().toString().trim();
                    int day = parseInt(eDay);
                    int month = parseInt(eMonth);
                    int year = parseInt(eYear);
                    if (titleText.isEmpty() || day < 1 || day > 31 || month < 1 || month > 12
                            || year < 2000 || year > 2100) return;
                    String timeText = eTime.getText().toString().trim();
                    String noteText = eNote.getText().toString().trim();
                    if (index >= 0) {
                        Data.Event e = Data.events.get(index);
                        e.title = titleText;
                        e.day = day;
                        e.month = month;
                        e.year = year;
                        e.time = timeText;
                        e.note = noteText;
                    } else {
                        Data.Event e = new Data.Event();
                        e.title = titleText;
                        e.day = day;
                        e.month = month;
                        e.year = year;
                        e.time = timeText;
                        e.note = noteText;
                        Data.events.add(e);
                    }
                    Data.saveBoletim(act);
                    showView();
                })
                .setNegativeButton("Cancelar", null)
                .show();
    }

    private void birthdayMenu(final int index) {
        new AlertDialog.Builder(act)
                .setTitle(Data.birthdays.get(index).name)
                .setItems(new String[]{"Editar", "Excluir"}, (d, w) -> {
                    if (w == 0) {
                        birthdayDialog(index);
                    } else {
                        Data.birthdays.remove(index);
                        Data.saveBoletim(act);
                        showView();
                    }
                })
                .setNegativeButton("Cancelar", null)
                .show();
    }

    private void eventMenu(final int index) {
        new AlertDialog.Builder(act)
                .setTitle(Data.events.get(index).title)
                .setItems(new String[]{"Editar", "Excluir"}, (d, w) -> {
                    if (w == 0) {
                        eventDialog(index);
                    } else {
                        Data.events.remove(index);
                        Data.saveBoletim(act);
                        showView();
                    }
                })
                .setNegativeButton("Cancelar", null)
                .show();
    }

    private List<Data.Birthday> birthdaysToday() {
        Calendar c = Calendar.getInstance();
        int m = c.get(Calendar.MONTH) + 1;
        int d = c.get(Calendar.DAY_OF_MONTH);
        List<Data.Birthday> out = new ArrayList<>();
        for (Data.Birthday b : Data.birthdays) {
            if (b.month == m && b.day == d) out.add(b);
        }
        return out;
    }

    private List<Data.Event> upcomingEvents() {
        Calendar today = Calendar.getInstance();
        today.set(Calendar.HOUR_OF_DAY, 0);
        today.set(Calendar.MINUTE, 0);
        today.set(Calendar.SECOND, 0);
        today.set(Calendar.MILLISECOND, 0);
        List<Data.Event> out = new ArrayList<>();
        for (Data.Event e : Data.events) {
            if (toMillis(e) >= today.getTimeInMillis()) out.add(e);
        }
        Collections.sort(out, (a, b) -> Long.compare(toMillis(a), toMillis(b)));
        return out;
    }

    private long toMillis(Data.Event e) {
        Calendar c = Calendar.getInstance();
        c.set(e.year, e.month - 1, e.day, 0, 0, 0);
        c.set(Calendar.MILLISECOND, 0);
        if (e.time != null && !e.time.isEmpty()) {
            try {
                String[] hm = e.time.split(":");
                int h = Integer.parseInt(hm[0].trim());
                int m = hm.length > 1 ? Integer.parseInt(hm[1].trim()) : 0;
                c.set(Calendar.HOUR_OF_DAY, h);
                c.set(Calendar.MINUTE, m);
            } catch (Exception ignore) {
                // mantém meia-noite
            }
        }
        return c.getTimeInMillis();
    }

    private String formatBirthdayDate(Data.Birthday b) {
        return String.format(Locale.ROOT, "%02d/%02d", b.day, b.month);
    }

    private String formatEventDate(Data.Event e) {
        return String.format(Locale.ROOT, "%02d/%02d/%04d", e.day, e.month, e.year);
    }

    private EditText field(String hint, boolean numeric) {
        EditText e = new EditText(act);
        e.setHint(hint);
        e.setTextSize(15 * Ui.FONT_SCALE);
        e.setSingleLine(true);
        if (numeric) e.setInputType(InputType.TYPE_CLASS_NUMBER);
        return e;
    }

    private int parseInt(EditText t) {
        try {
            return Integer.parseInt(t.getText().toString().trim());
        } catch (Exception e) {
            return -1;
        }
    }

    private LinearLayout card() {
        LinearLayout item = Ui.column(act);
        item.setBackgroundColor(Ui.CARD);
        item.setPadding(Ui.dp(act, 14), Ui.dp(act, 10), Ui.dp(act, 14), Ui.dp(act, 10));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        lp.topMargin = Ui.dp(act, 5);
        lp.leftMargin = Ui.dp(act, 8);
        lp.rightMargin = Ui.dp(act, 8);
        item.setLayoutParams(lp);
        return item;
    }

    private TextView none(String s) {
        TextView t = Ui.text(act, s, 14, Ui.MUTED, false);
        t.setPadding(Ui.dp(act, 16), Ui.dp(act, 8), Ui.dp(act, 16), Ui.dp(act, 8));
        return t;
    }
}