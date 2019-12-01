namespace Tokenized {
    public abstract class CompleterDelegate : Object {
        public Completer completer { construct; get; }
        public string query = "";

        protected void suggest(string val, string label = "-") {
            completer.@yield(val, label == "-" ? val : label);
        }

        public abstract void autocomplete();
    }

    private class Completion : Object {
        public string val {get; set;}
        public string label {get; set;}

        public Completion(string val, string label) {
            this.val = val;
            this.label = label;
        }
    }

    public class Completer : Object {
        public ListStore model = new ListStore(typeof(Completion));
        private Gee.List<CompleterDelegate> delegates = new Gee.ArrayList<CompleterDelegate>();
        private Gee.Set<string> seen = new Gee.HashSet<string>();

        public void add_type(Type type) {
            var completer = Object.@new(type, "completer", this) as CompleterDelegate;
            if (completer != null) delegates.add(completer);
        }

        public delegate void YieldCallback(string url, string label);
        private YieldCallback yieldCallback;
        public void suggest(string query, owned YieldCallback cb) {
            this.yieldCallback = cb;
            seen.clear();

            foreach (var completer in delegates) {
                completer.query = query;
                completer.autocomplete();
            }
        }

        public void @yield(string val, string label) {
            if (val in seen) return;
            seen.add(val);

            yieldCallback(val, label);
        }
    }

    public class CompleterFactory : Object {
        private Gee.List<Type> delegate_classes = new Gee.ArrayList<Type>();

        public void register(Type completer) {
            delegate_classes.add(completer);
        }

        public Completer build() {
            var ret = new Completer();
            foreach (var source in delegate_classes) ret.add_type(source);
            return ret;
        }
    }
}
