using Gtk;

public class TokenizedEntry : Grid {
    private Entry entry;
    private Button clear_button;
    private Grid grid;

    public class Token {
        public string label;
        public float hue;
        public Token(string label, float hue = 1.0f) {
            this.label = label; this.hue = hue;
        }
    }
    private Gee.List<Token> _tokens = new Gee.ArrayList<Token>();
    public unowned Gee.List<Token> tokens {
        set {
            _tokens.clear();
            _tokens.add_all(value);
            rebuild_tokens();
        }
        get {return _tokens;}
    }

    /* -- expand to fill -- */
    public int max_width {get; set; default = 840;} // Something large

    // This approximates the expand to fill effect.
    public override void get_preferred_width(out int min_width, out int nat_width) {
        min_width = 20; // Meh
        nat_width = max_width;
    }

    /* -- read in autocompletions -- */
    public string[] autocompletions;

    public void read_autocompletions(string filename) throws Error {
        var file = FileStream.open(filename, "r");

        var line = "";
        var autocompletions = new Gee.ArrayList<string>();
        while ((line = file.read_line()) != null) autocompletions.add(line.strip());
        this.autocompletions = autocompletions.to_array();
    }

    /* -- autocompletion -- */
    private Gtk.Popover popover;
    private Gtk.ListBox list;
    private int selected = 0;

    private void autocomplete_connect_events() {
        entry.changed.connect(autocomplete);

        entry.focus_in_event.connect((evt) => {
            popover.show_all();
            autocomplete();

            return false;
        });
        entry.focus_out_event.connect((evt) => {
            popover.hide();
            return false;
        });
        entry.key_press_event.connect((evt) => {
            switch (evt.keyval) {
            case Gdk.Key.Up:
            case Gdk.Key.KP_Up:
                selected--;
                break;
            case Gdk.Key.Down:
            case Gdk.Key.KP_Down:
                selected++;
                break;
            default:
                return false;
            }

            if (list.get_row_at_index(selected) == null)
                return true; // Don't go beyond the boundaries.

            list.select_row(list.get_row_at_index(selected));
            return true;
        });
        entry.activate.connect(() => {
            var row = list.get_selected_row();
            if (row == null && !(row is TextRow)) return;

            addtoken(row as TextRow);
        });

        list.row_activated.connect((row) => {
            addtoken(row as TextRow);
        });
    }

    public class TextRow : ListBoxRow {
        public string label = "";
        public TextRow(string label) {
            this.label = label;
            add(new Gtk.Label(label));
            show_all();
        }
    }

    private void autocomplete() {
        list.@foreach((widget) => {list.remove(widget);});

        foreach (var completion in autocompletions) if (entry.text in completion) {
            list.add(new TextRow(completion));

            /* Ensure a row is selected. */
            if (list.get_children().length() == 1) {
                list.select_row(list.get_row_at_index(0));
                this.selected = 0;
            }
        }
    }

    private void build_autocomplete() {
        list = new Gtk.ListBox();
        list.activate_on_single_click = true;
        list.selection_mode = Gtk.SelectionMode.BROWSE;

        var scrolled = new Tokenized.AutomaticScrollBox();
        scrolled.add(list);
        scrolled.shadow_type = Gtk.ShadowType.IN;

        popover = new Gtk.Popover(this);
        popover.add(scrolled);
        popover.modal = false;
        popover.position = Gtk.PositionType.BOTTOM;

        this.size_allocate.connect((box) => scrolled.width_request = box.width);

        autocomplete_connect_events();
    }

    /* -- tokens -- */
    public void addtoken(TextRow row) {
        _tokens.add(new Token(row.label));
        rebuild_tokens();
    }

    private void _addtoken(Token row) {
        var token = new Button.with_label(row.label);
        token.tooltip_text = "Remove '%s'".printf(row.label);
        grid.add(token);
        token.show_all();

        token.clicked.connect(() => {
            entry.text = row.label; // FIXME: This text isn't coming over.
            entry.grab_focus();

            _tokens.remove(row);
            rebuild_tokens();
        });

        apply_token_styles(token);

        entry.text = "";
        clear_button.no_show_all = false;
        clear_button.show_all();
    }

    private void rebuild_tokens() {
        foreach (var child in grid.get_children()) child.destroy();
        foreach (var token in _tokens) _addtoken(token);

        if (_tokens.size == 0) clear_button.hide();
        else clear_button.show_all();
    }

    /* -- styles -- */
    private const string STYLESHEET = """
        .token {
            background: #3689e6;
            color: #fff;
            border-radius: 8px;
            margin: 0 2px;
            padding: 0;
        }
        .token:focus {background: #0d52bf;}
    """;

    private void apply_token_styles(Gtk.Button token) {
        var styles = token.get_style_context();

        styles.add_class("token");

        try {
            var stylesheet = new Gtk.CssProvider();
            stylesheet.load_from_data(STYLESHEET);
            styles.add_provider(stylesheet, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error err) {}
    }

    /* -- entrypoint -- */
    construct {
        get_style_context().add_class(STYLE_CLASS_LINKED);

        orientation = Gtk.Orientation.HORIZONTAL;
        notify["max-width"].connect(queue_resize);

        clear_button = new Button();
        clear_button.get_style_context().add_class(STYLE_CLASS_ENTRY);
        clear_button.no_show_all = true;
        clear_button.clicked.connect(() => {
            _tokens.clear();
            rebuild_tokens();
        });
        clear_button.can_focus = false;
        add(clear_button);

        grid = new Gtk.Grid();
        clear_button.add(grid);

        entry = new Gtk.Entry();
        entry.hexpand = true;
        entry.halign = Gtk.Align.FILL;
        add(entry);

        build_autocomplete();
        //apply_styles();
    }
}
