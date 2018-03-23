using Gtk;

public class TokenizedEntry : ScrolledWindow {
    private Entry entry;
    private Grid grid;

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

    private class TextRow : ListBoxRow {
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

        var scrolled = new AutomaticScrollBox();
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
    private void addtoken(TextRow row) {
        var token = new Button.with_label(row.label);
        token.tooltip_text = "Edit/remove '%s' tag".printf(row.label);
        grid.insert_next_to(entry, Gtk.PositionType.LEFT);
        grid.attach_next_to(token, entry, Gtk.PositionType.LEFT);
        token.show_all();

        token.clicked.connect(() => {
            entry.text = token.label;
            entry.grab_focus();

            popover.show_all();
            autocomplete();

            token.destroy();
        });

        apply_token_styles(token);

        entry.text = "";
    }

    /* -- styles -- */
    private const string STYLESHEET = """
        .token {
            background: #3689e6;
            color: #fff;
            border-radius: 20px;
        }
        .token:focus {background: #0d52bf;}
    """;

    private void apply_styles() {
        get_style_context().add_class(Gtk.STYLE_CLASS_ENTRY);

        entry.get_style_context().remove_class(Gtk.STYLE_CLASS_ENTRY);
        // FIXME bring back focused styles.
    }

    private void apply_token_styles(Gtk.Button token) {
        var styles = token.get_style_context();

        styles.add_class("token");
        token.margin_left = 4;

        try {
            var stylesheet = new Gtk.CssProvider();
            stylesheet.load_from_data(STYLESHEET);
            styles.add_provider(stylesheet, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error err) {}
    }

    /* -- entrypoint -- */
    construct {
        vscrollbar_policy = Gtk.PolicyType.NEVER;
        hscrollbar_policy = Gtk.PolicyType.EXTERNAL;

        grid = new Gtk.Grid();
        add(grid);

        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.notify["max-width"].connect(queue_resize);

        entry = new Gtk.Entry();
        entry.hexpand = true;
        entry.halign = Gtk.Align.FILL;
        grid.add(entry);

        build_autocomplete();
        apply_styles();
    }
}
