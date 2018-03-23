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
}
