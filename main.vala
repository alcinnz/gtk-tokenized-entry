using Gtk;

private class ValaLibsCompleter : Tokenized.CompleterDelegate {
    string[] libs = new string[0];

    construct {
        try {
            var file = FileStream.open("../vala-libs.txt", "r");

            var line = "";
            var autocompletions = new Gee.ArrayList<string>();
            while ((line = file.read_line()) != null) autocompletions.add(line.strip());
            libs = autocompletions.to_array();
        } catch (Error err) {
            // Heros from The Red Panda Adventures
            this.libs = {"Red Panda", "Flying Squirrel", "The Stranger", "Man of a Thousand Faces", "Tom Tomorrow, Man of Tomorrow", "The Ogre", "Molecule Max", "Lady Luck", "Red Ensenn"};
        }
    }
    public override void autocomplete(string query, Tokenized.Completer completer) {
        assert(completer != null);
        foreach (var lib in libs) if (query in lib) completer.token(lib);
    }
}

class MyWindow : Window {
    construct {
        var header = new HeaderBar();
        header.show_close_button = true;
        set_titlebar(header);

        var entry = new TokenizedEntry();
        entry.autocompleter.add_type(typeof(ValaLibsCompleter));
        header.custom_title = entry;
        header.size_allocate.connect((box) => entry.max_width = box.width);

        var button = new Gtk.Button.with_label("CLICK ME!");
        add(button);
    }

    public static int main(string[] args) {
        Gtk.init(ref args);
        var win = new MyWindow();
        win.show_all();

        win.destroy.connect(Gtk.main_quit);
        Gtk.main();
        return 0;
    }
}
