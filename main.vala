using Gtk;

class MyWindow : Window {
    construct {
        var header = new HeaderBar();
        header.show_close_button = true;
        set_titlebar(header);

        var entry = new TokenizedEntry();
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
