using Gtk;

public class TokenizedEntry : Entry {
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
        changed.connect(autocomplete);

        this.focus_in_event.connect((evt) => {
            popover.show_all();
            autocomplete();

            Idle.add(() => {
                this.select_region(0, -1);
                return false;
            }, Priority.HIGH); // To aid retyping URLs, copy+paste
            return false;
        });
        this.focus_out_event.connect((evt) => {
            popover.hide();
            return false;
        });
        this.key_press_event.connect((evt) => {
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
        this.activate.connect(() => {
            var row = list.get_selected_row();
            if (row == null && !(row is TextRow)) return;
            this.text = (row as TextRow).label;

            // Remove focus from text entry
            get_toplevel().grab_focus();
        });

        list.row_activated.connect((row) => {
            // TODO
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

        foreach (var completion in autocompletions) if (this.text in completion) {
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

    /* -- entrypoint -- */
    construct {
        notify["max-width"].connect(queue_resize);

        build_autocomplete();
    }
}
