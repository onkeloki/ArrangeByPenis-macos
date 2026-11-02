# Arrange by Penis 🍆

Finder only lets you sort desktop icons by name, kind, date or size.
This tiny macOS app adds the sort option it's been missing: **Arrange by Penis**.

Click the button and every visible icon on your desktop is moved into the shape.
It adapts to the number of icons and to your screen size. Click **Undo** to put
them back.

## Why does this exist?

If you're a child of the 80s, you might remember a certain internet classic:
**"The Website Is Down: Sales Guy vs. Web Dude"**. If you don't, go fix that
right now:
[search for it on YouTube](https://www.youtube.com/results?search_query=the+website+is+down+sales+guy+vs.+web+dude).
We'll wait.

Back then, some things were simply impossible. You could not, under any
circumstances, arrange your icons by penis.

After decades of progress, we now have artificial intelligence trained on a
mind-boggling share of human knowledge. And at last there's proof that AI is
good for something: an AI wrote this app in a single conversation, because
someone asked nicely.

This project is a heartfelt homage to that video. No sales guys were harmed in
the making of this app.

## Build

Requires Xcode Command Line Tools (`xcode-select --install`).

```sh
./build.sh
open "Arrange by Penis.app"
```

## Notes

- On the first click macOS asks for permission to control Finder. Allow it,
  or enable it later in System Settings → Privacy & Security → Automation.
- Before the first arrangement, the original positions are saved to
  `~/Library/Application Support/ArrangeByPenis/backup.tsv`.
  Undo restores icons that had a fixed position; the rest are tidied up with
  Finder's "Clean Up".
- Hidden files are left alone.
- The app is ad-hoc signed. On other Macs, open it via right-click → Open the
  first time.

## License

MIT – see [LICENSE](LICENSE).
