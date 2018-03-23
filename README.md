# gtk-tokenized-entry
Experimental tokenized Gtk.Entry for use in Odysseus; also useful elsewhere.

This is fully accessible via keyboard or mouse input, and visual or screenreader output. It presents visually as a number of "tokens" preceding the text in a Gtk.Entry, but is interacted with via keyboard or screenreader as a bunch buttons preceding the Gtk.Entry. I'm open to improvements, but am quite happy with it as is.

It's intended to be used for when you need a sequence of textual information to be entered, and can't spare much screenspace for it. Generally there'd be a predefined list of items to select from, but freeform tags might also be entered.

---

The main use will I have for this is to use it as an enhancment to the Odysseus addressbar, where it'll take many forms. It might act as a somewhat normal Gtk.Entry with a range of autocompleters. Or it might behave like this tokenized entry to aid bookmark search. And that addressbar may addionally have iconic toggle buttons on it's right-hand-side.
