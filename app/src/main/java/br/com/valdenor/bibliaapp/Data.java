package br.com.valdenor.bibliaapp;

import android.content.Context;
import android.content.res.AssetManager;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Data {

    public static class Book {
        public final String abbr;
        public final String name;
        public final List<List<String>> chapters;

        Book(JSONObject o) throws Exception {
            String a = o.optString("abbr");
            if (a.isEmpty()) a = o.getString("abbrev");
            abbr = a;
            name = o.getString("name");
            JSONArray chs = o.has("ch") ? o.getJSONArray("ch") : o.getJSONArray("chapters");
            chapters = new ArrayList<>();
            for (int i = 0; i < chs.length(); i++) {
                JSONArray cv = chs.getJSONArray(i);
                List<String> vs = new ArrayList<>();
                for (int j = 0; j < cv.length(); j++) vs.add(cv.getString(j));
                chapters.add(vs);
            }
        }
    }

    public static class Hymn {
        public final int num;
        public final String title;
        public final String author;
        public final List<String> stanzaNames;
        public final List<List<String>> stanzas;

        Hymn(JSONObject o) throws Exception {
            num = o.getInt("num");
            title = o.getString("title");
            author = o.optString("author", "");
            JSONArray vs = o.getJSONArray("verses");
            stanzaNames = new ArrayList<>();
            stanzas = new ArrayList<>();
            for (int i = 0; i < vs.length(); i++) {
                JSONObject v = vs.getJSONObject(i);
                stanzaNames.add(v.optString("name", ""));
                JSONArray lines = v.getJSONArray("lines");
                List<String> ll = new ArrayList<>();
                for (int j = 0; j < lines.length(); j++) ll.add(lines.getString(j));
                stanzas.add(ll);
            }
        }

        public String searchText() {
            StringBuilder sb = new StringBuilder(title).append(' ').append(author).append(' ');
            for (List<String> s : stanzas) for (String l : s) sb.append(l).append(' ');
            return sb.toString().toLowerCase();
        }
    }

    public static class Song {
        public String title;
        public String lyrics;

        Song(JSONObject o) throws Exception {
            title = o.getString("title");
            lyrics = o.optString("lyrics", "");
        }

        public Song() {}
    }

    public static class Birthday {
        public String name;
        public int day;
        public int month;

        Birthday(JSONObject o) throws Exception {
            name = o.getString("name");
            day = o.getInt("day");
            month = o.getInt("month");
        }

        public Birthday() {}
    }

    public static class Event {
        public String title;
        public int day;
        public int month;
        public int year;
        public String time;
        public String note;

        Event(JSONObject o) throws Exception {
            title = o.getString("title");
            day = o.getInt("day");
            month = o.getInt("month");
            year = o.getInt("year");
            time = o.optString("time", "");
            note = o.optString("note", "");
        }

        public Event() {}
    }

    public static volatile List<Book> bible = new ArrayList<>();
    public static final Map<String, List<Book>> bibles = new HashMap<>();
    public static volatile List<Hymn> hymns = new ArrayList<>();
    public static volatile List<Song> songs = new ArrayList<>();
    public static volatile List<Birthday> birthdays = new ArrayList<>();
    public static volatile List<Event> events = new ArrayList<>();
    public static String selectedVersion = "ara";

    public static final String[] VERSION_ORDER = {"ara", "nvi", "ntlh", "jfaal"};
    public static final String[] VERSION_NAMES = {
            "Almeida Revista e Atualizada",
            "Nova Versão Internacional",
            "Nova Tradução na Linguagem de Hoje",
            "João Ferreira de Almeida Atualizada Livre"
    };
    public static final String[] VERSION_ABBRS = {"ARA", "NVI", "NTLH", "JFAA"};

    private static final String KEY_VERSION = "biblia_version";
    private static volatile boolean loaded = false;

    public static synchronized void load(Context ctx) {
        if (loaded) return;
        bibles.clear();
        try {
            List<Book> jfaal = loadBible(ctx, "biblia.json");
            bibles.put("jfaal", jfaal);
            bibles.put("ara", loadBible(ctx, "biblia_ara.json"));
            bibles.put("nvi", loadBible(ctx, "biblia_nvi.json"));
            bibles.put("ntlh", loadBible(ctx, "biblia_ntlh.json"));
            selectedVersion = ctx.getSharedPreferences(Ui.PREF_THEME, 0).getString(KEY_VERSION, "ara");
            List<Book> cur = bibles.get(selectedVersion);
            bible = cur != null ? cur : jfaal;
            JSONArray ha = new JSONArray(readAsset(ctx, "hinos.json"));
            for (int i = 0; i < ha.length(); i++) hymns.add(new Hymn(ha.getJSONObject(i)));
            songs = loadSongs(ctx);
            loadBoletim(ctx);
            loaded = true;
        } catch (Exception e) {
            bibles.clear();
            bible = new ArrayList<>();
            throw new RuntimeException("Falha ao carregar dados: " + e.getMessage(), e);
        }
    }

    private static List<Book> loadBible(Context ctx, String asset) throws Exception {
        JSONArray ba = new JSONArray(readAsset(ctx, asset));
        List<Book> books = new ArrayList<>();
        for (int i = 0; i < ba.length(); i++) books.add(new Book(ba.getJSONObject(i)));
        return books;
    }

    public static void setVersion(Context ctx, String code) {
        List<Book> target = bibles.get(code);
        if (target == null) return;
        selectedVersion = code;
        bible = target;
        ctx.getSharedPreferences(Ui.PREF_THEME, 0).edit().putString(KEY_VERSION, code).apply();
    }

    public static String readAsset(Context ctx, String name) throws Exception {
        AssetManager am = ctx.getAssets();
        InputStream is = am.open(name);
        BufferedReader r = new BufferedReader(new InputStreamReader(is, "UTF-8"));
        StringBuilder sb = new StringBuilder();
        String line;
        while ((line = r.readLine()) != null) sb.append(line).append('\n');
        r.close();
        return sb.toString();
    }

    private static File songsFile(Context ctx) {
        return new File(ctx.getFilesDir(), "musicas.json");
    }

    public static synchronized List<Song> loadSongs(Context ctx) {
        List<Song> list = new ArrayList<>();
        try {
            File f = songsFile(ctx);
            if (!f.exists()) {
                String template = readAsset(ctx, "musicas.json");
                FileOutputStream os = new FileOutputStream(f);
                os.write(template.getBytes("UTF-8"));
                os.close();
            }
            BufferedReader r = new BufferedReader(new FileReader(f));
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = r.readLine()) != null) sb.append(line).append('\n');
            r.close();
            JSONArray arr = new JSONArray(sb.toString());
            for (int i = 0; i < arr.length(); i++) list.add(new Song(arr.getJSONObject(i)));
        } catch (Exception e) {
            // ignora erros; lista vazia
        }
        return list;
    }

    public static synchronized void saveSongs(Context ctx) {
        try {
            JSONArray arr = new JSONArray();
            for (Song s : songs) {
                JSONObject o = new JSONObject();
                o.put("title", s.title);
                o.put("lyrics", s.lyrics);
                arr.put(o);
            }
            FileOutputStream os = new FileOutputStream(songsFile(ctx));
            os.write(arr.toString(2).getBytes("UTF-8"));
            os.close();
        } catch (Exception e) {
            // ignora
        }
    }

    private static File boletimFile(Context ctx) {
        return new File(ctx.getFilesDir(), "boletim.json");
    }

    public static synchronized void loadBoletim(Context ctx) {
        birthdays.clear();
        events.clear();
        try {
            File f = boletimFile(ctx);
            if (!f.exists()) {
                FileOutputStream os = new FileOutputStream(f);
                os.write(readAsset(ctx, "boletim.json").getBytes("UTF-8"));
                os.close();
            }
            BufferedReader r = new BufferedReader(new FileReader(f));
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = r.readLine()) != null) sb.append(line).append('\n');
            r.close();
            JSONObject obj = new JSONObject(sb.toString());
            JSONArray b = obj.optJSONArray("aniversariantes");
            if (b != null) for (int i = 0; i < b.length(); i++) birthdays.add(new Birthday(b.getJSONObject(i)));
            JSONArray e = obj.optJSONArray("eventos");
            if (e != null) for (int i = 0; i < e.length(); i++) events.add(new Event(e.getJSONObject(i)));
        } catch (Exception e) {
            birthdays.clear();
            events.clear();
        }
    }

    public static synchronized void saveBoletim(Context ctx) {
        try {
            JSONArray bArr = new JSONArray();
            for (Birthday b : birthdays) {
                JSONObject o = new JSONObject();
                o.put("name", b.name);
                o.put("day", b.day);
                o.put("month", b.month);
                bArr.put(o);
            }
            JSONArray eArr = new JSONArray();
            for (Event ev : events) {
                JSONObject o = new JSONObject();
                o.put("title", ev.title);
                o.put("year", ev.year);
                o.put("month", ev.month);
                o.put("day", ev.day);
                if (ev.time != null && !ev.time.isEmpty()) o.put("time", ev.time);
                if (ev.note != null && !ev.note.isEmpty()) o.put("note", ev.note);
                eArr.put(o);
            }
            JSONObject obj = new JSONObject();
            obj.put("aniversariantes", bArr);
            obj.put("eventos", eArr);
            FileOutputStream os = new FileOutputStream(boletimFile(ctx));
            os.write(obj.toString(2).getBytes("UTF-8"));
            os.close();
        } catch (Exception e) {
            // ignora
        }
    }
}