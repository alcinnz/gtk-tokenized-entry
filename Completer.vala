namespace Tokenized {
    public abstract class CompleterDelegate : Object {
        public Completer completer { construct; get; }
        public string query = "";

        protected void suggest(string val, string? label = null) {
            completer.@yield(new Completion(val, label == null ? val : label));
        }
        protected void token(string val, string? label = null, Completer? completer = null) {
            completer.@yield(new Completion.token(val, label == null ? val : label, completer));
        }

        public abstract void autocomplete();
    }

    public class Completion : Object {
        public string val {get; set;}
        public string label {get; set;}
        public Completer? completer = null;
        public bool is_token;

        public Completion(string val, string label) {
            this.val = val;
            this.label = label;
            this.is_token = false;
        }
        public Completion.token(string val, string label, Completer? completer = null) {
            this.val = val;
            this.label = label;
            this.is_token = true;
            this.completer = completer;
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

        public delegate void YieldCallback(Completion completion);
        private YieldCallback yieldCallback;
        public void suggest(string query) {
            seen.clear();

            foreach (var completer in delegates) {
                completer.query = query;
                completer.autocomplete();
            }
        }

        public void @yield(Completion completion) {
            if (completion.val in seen) return;
            seen.add(completion.val);

            yieldCallback(completion);
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
