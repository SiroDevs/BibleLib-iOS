# BibleLib iOS — Step 1 (bare minimum)

Built on the same architectural footprint as your **SwahiLib** iOS app
(Core/Di, Domain, Data, Feature, Swinject DI, Core Data, manual MVVM),
so this slots into your existing workflow rather than introducing a new
pattern.

## What's implemented

The smallest possible vertical slice through the whole pipeline:

**Splash → Selection (pick + download Bibles) → Reader (single Bible, one
chapter at a time)**

- Fetches the real Bible list from `https://biblive.vercel.app/info.json`
- Lets you multi-select Bibles, mark one primary (tap the star), and download
- Download walks books → chapters → verses per Bible, with bounded
  concurrency across books (8 at a time)
- The verse parser is a faithful Swift port of your Android `BibleRepo.
  extractVerses` — same recursive walk of the tag/text content tree, same
  lenient handling of non-string `attrs` values and stray `null` content
  entries
- Everything is cached in Core Data (`CDBible`, `CDBook`, `CDChapter`,
  `CDVerse` — same shape as the Room entities, `CDVerse.contentJson` caches
  a chapter's flattened verses the same way `VerseEntity` does on Android)
- Reader shows the current chapter's verses and lets you step forward/back
  across chapter *and* book boundaries

## What's deliberately left out (see the earlier feature-map doc)

- Search, Bookmarks, Notes, History
- Scripture Opener / Scripture Lists / queue
- Parallel/multi-Bible reading, page-curl transition
- Settings, Donation
- Casting (needs a design decision — see the feature-map doc)
- Retry/backoff on failed network calls (a failed chapter is skipped; a
  failed books/chapters fetch fails that Bible's whole download)
- A dedicated background `NSManagedObjectContext` for downloads (writes go
  through the shared `viewContext` for now — fine at this scale, worth
  revisiting once whole-Bible downloads need to feel fast)
- Region/language grouping and the "returning user" re-selection flow on
  the Selection screen

## Setting it up in Xcode

This zip is source files only (no `.xcodeproj`), same as how you shared
SwahiLib's footprint. To get it running:

1. Create a new iOS App project in Xcode named **BibleLib** (SwiftUI
   interface, Swift language, no Core Data template checkbox — we're
   supplying our own model).
2. Delete the placeholder `ContentView.swift` and default
   `BibleLib.xcdatamodeld` Xcode generates, and drag in everything from
   this zip's `BibleLib/` folder, keeping the folder structure ("Create
   groups", not "Create folder references" — matches how SwahiLib is set
   up).
3. Add **Swinject** via Swift Package Manager:
   `https://github.com/Swinject/Swinject`
4. Build target ▸ Info: nothing extra needed for step 1 (no notification
   permissions, no App Transport Security exceptions — the API is HTTPS).
5. Build and run. First launch: Splash → Selection (pulls the live Bible
   list) → pick one or two short ones to test with (download time scales
   with book/chapter count) → Reader.

## A few notes on faithfulness vs. shortcuts

- `attrs` lenient decoding, the null-entry tolerance in `content`, and the
  verse-text-append-if-same-verseId behavior are all copied from the real
  Android parsing logic — these aren't guesses, they were pulled directly
  from your Kotlin source, because the live API payload actually needs them.
- `BibleDataManager.saveBibles` intentionally **never touches download
  state** when re-syncing the Bible list, so re-fetching `info.json` can't
  wipe out a Bible you've already downloaded — worth keeping in mind if you
  later change that assumption.
- Colors/fonts use plain system semantics (`.accentColor`, `.secondary`,
  SF Symbols) since your asset catalog wasn't part of the shared export —
  swap in your real palette whenever design_system work starts.
