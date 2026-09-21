# BibleLib: Multi-Bible Reader for iOS

A clean, offline-first Bible reader built for focused study. Explore a number of translations side by side, search instantly, personalize your reading experience, and keep everything organized with bookmarks, notes, reading history, and reusable scripture lists for sermons, studies, or personal devotions.

---

## Features

READ YOUR WAY
- Download multiple Bible translations and switch between them freely
- Parallel reading — view your primary translation alongside other translations under each verse
- Jump between books and chapters with a simple, fast navigator
- Your last-read verse is remembered automatically so you always pick up where you left off
- Auto-scroll for hands-free reading

FIND ANY VERSE FAST
- Full-text search across your downloaded Bibles
- Recent searches saved for quick access
- Look up a specific reference directly — book, chapter, and verse — with the Scripture Opener
- Save frequently used passages into custom scripture lists you can reopen anytime, and queue up several passages to read through in one sitting

BOOKMARKS, HIGHLIGHTS & NOTES
- Swipe a verse to bookmark it, or to add a note
- Long-press to select one or more verses, highlight them in a color of your choice, copy or share them
- Browse and manage all your bookmarks and notes in one place

HISTORY
- Automatic reading history, grouped by day, so you can retrace your steps

MAKE IT YOURS
- 10 reader background themes, from soft parchment and sepia tones to dark options like Night, Charcoal, and Forest
- 13 typefaces built into iOS, including New York, Georgia, Palatino, and Avenir Next
- Adjustable font size that also respects Dynamic Type
- Light, dark, or system appearance

BUILT FOR OFFLINE USE
- Download a Bible once, then read, search, and study without an internet connection
- Download progress, retry, and re-download controls if a download is interrupted

---

## Table of contents

- [Tech stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Project structure](#project-structure)
- [Architecture overview](#architecture-overview)
    - [Layers](#layers)
    - [Dependency injection](#dependency-injection)
    - [Screens and view models](#screens-and-view-models)
    - [Navigation](#navigation)
    - [Persistence](#persistence)
    - [Data flow and downloads](#data-flow-and-downloads)
    - [Theming](#theming)
- [Getting started](#getting-started)
    - [1. Clone the repository](#1-clone-the-repository)
    - [2. Open the project](#2-open-the-project)
    - [3. Run the app](#3-run-the-app)
    - [4. Release builds (optional)](#4-release-builds-optional)
- [Contributing](#contributing)

---

## Tech stack

| Concern              | Library / tool                                                   |
|----------------------|------------------------------------------------------------------|
| UI                   | SwiftUI (native controls: `NavigationStack`, `List`, sheets)     |
| Architecture         | MVVM with `ObservableObject` view models                         |
| Dependency injection | [Swinject](https://github.com/Swinject/Swinject) (SPM)          |
| Local database       | Core Data (`BibleLib.xcdatamodeld`)                              |
| Networking           | `URLSession` with `async`/`await`                                |
| Concurrency          | Swift concurrency (`Task`, `TaskGroup`), Combine for bindings    |
| Preferences          | `UserDefaults` via `PrefsRepo` and `@AppStorage`                 |
| Connectivity         | `NWPathMonitor` (`Network` framework)                            |
| Language             | Swift 5                                                          |
| Minimum iOS          | 16.0 (iPhone and iPad)                                           |

---

## Prerequisites

- **macOS** with **Xcode 16** or newer
- An **iOS 16+** simulator or device
- Internet access the first time you open the project so Swift Package Manager can fetch Swinject

---

## Project structure

```
BibleLib/
├── BibleLib.xcodeproj
├── BibleLib/
│   ├── BibleLibApp.swift              # @main — creates ThemeManager, shows SplashView
│   ├── Assets.xcassets                # App icons, MainIcon, and the theme color sets
│   │
│   ├── Core/
│   │   ├── Di/                        # DiContainer + DependencyMap (Swinject registrations)
│   │   ├── Theme/                     # ThemeManager, AppColors, ThemeSelectorSheet
│   │   ├── Ui/
│   │   │   ├── Components/            # ErrorState, EmptyState, LoadingState, ModalNavigation, MailComposeView
│   │   │   └── Reader/                # Reader typefaces, page backgrounds, highlight colors
│   │   └── Utils/                     # Constants, NetworkUtils, RetryPolicy, SyncScheduler, RestartAppAction
│   │
│   ├── Data/
│   │   ├── Sources/Local/             # Core Data model, managers, value types
│   │   ├── Sources/Mappers/           # Core Data object → value type mapping
│   │   └── Sources/Remote/            # BibleLibApiService and its DTOs
│   │
│   ├── Domain/
│   │   ├── Entity/                    # UiState, Selectable, ReaderTarget and other shared types
│   │   └── Repos/                     # BibleRepo, PrefsRepo, AnnotationRepo, TrackingRepo, ScriptureRepo, …
│   │
│   └── Feature/
│       ├── Splash/                    # Launch screen and start-up work
│       ├── Selection/                 # First-launch / re-selection Bible picker
│       ├── Reader/                    # Chapter reader, notes editor, pickers
│       ├── Search/                    # Full-text verse search + recent searches
│       ├── History/                   # Reading history
│       ├── BookmarkNotes/             # Bookmarks and notes lists
│       ├── Bibles/                    # Manage primary / secondary Bibles and downloads
│       ├── ScriptureOpener/           # Reference lookup, queues, and saved scripture lists
│       ├── Settings/                  # Appearance, reading, and app-data settings
│       └── Help/                      # Help & feedback, How it works
│
├── BibleLibTests/
└── BibleLibUITests/
```

Each feature folder follows the same shape: `View/` (SwiftUI screens and components) and `ViewModel/`.

---

## Architecture overview

### Layers

Dependencies point one way: **Feature → Domain → Data**, with **Core** available to all of them.

- **Data** — the Core Data stack and the network service. Managers (`BibleDataManager`, `UserDataManager`) do all database work on a single private-queue context, so they are safe to call from any thread and never block the main thread.
- **Domain** — repositories that combine local and remote sources and expose plain value types (`Bible`, `Book`, `Chapter`, `VerseDisplay`, `Bookmark`, `Note`, `HistoryEntry`, …). `PrefsRepo` wraps `UserDefaults`.
- **Feature** — screens and their view models.
- **Core** — shared utilities, theme, and reusable views with no feature knowledge.

### Dependency injection

`DependencyMap` registers repositories, managers, and view models in one Swinject `Container`; `DiContainer` builds it once and checks that every registration resolves. Views obtain their view model with:

```swift
@StateObject private var viewModel = DiContainer.shared.resolve(HistoryViewModel.self)
```

Repositories are registered in the container object scope (one instance); view models are created fresh for each screen.

### Screens and view models

View models are `ObservableObject`s with `@Published` state. Larger screens are split into small collaborating types instead of one large class — for example the reader is `ReaderViewModel` (navigation and loading) plus `VerseSelectionModel` (selection, bookmarks, notes), `ParallelChapter`, `ReadingProgress`, and `ReaderShareText`.

Simple user settings (font size, typeface, page background, multi-Bible toggle) are read directly by views through `@AppStorage`, using the same keys as `PrefsRepo`.

### Navigation

Navigation uses SwiftUI's own tools; there is no custom router.

```
SplashView
 ├─ SelectionView                    first launch, until the primary Bible has downloaded
 └─ NavigationStack ─ ReaderView
       ├─ push   Settings ─► Appearance · Reading · Manage Bibles · App Data · Help · How It Works
       ├─ sheet  Search · History · Bookmarks & Notes · Scripture Lists · Scripture Opener
       ├─ sheet  Book / Chapter / Bible pickers · Quick settings · Highlight colors
       └─ sheet  Note editor
```

Screens presented as sheets receive an `onOpen: (ReaderTarget) -> Void` closure; choosing a search result, bookmark, history entry, or scripture list item calls it and the reader jumps there. Clearing all data in Settings calls the `restartApp` environment action, which returns to Bible selection.

### Persistence

Core Data entities: `CDBible`, `CDBook`, `CDChapter`, `CDVerse` (downloaded content), and `CDBookmark`, `CDNote`, `CDHistory`, `CDSearch`, `CDScriptureList`, `CDScriptureItem` (user data). Managers map them to plain Swift value types before they leave the data layer.

The store has a single model version and no migrations, since the app has not shipped yet. Once it does, schema changes need a new model version and a mapping.

### Data flow and downloads

The content API is a set of static JSON files:

```
{base}/info.json                          list of Bible groups
{base}/{group}/info.json                  Bibles in a group
{base}/{path}/books.json                  books of a Bible
{base}/{path}/chapters.json               chapters, keyed by book
{base}/{path}/verses/{bookId}/{n}.json    one chapter's verses
```

When you pick Bibles in `SelectionView`, the first one becomes the primary. `BibleRepo.downloadBible` fetches books, then chapters, then verses — up to 20 books at a time with a `TaskGroup` — and saves each book's chapters in a single Core Data batch. Every request goes through `RetryPolicy` (exponential backoff, `Retry-After` support, fail-fast on 401/403/404). Chapters that are already stored are skipped, so an interrupted download resumes where it stopped.

The primary Bible downloads in the foreground with a progress screen and Restart / Continue controls if it fails. The remaining Bibles are queued in `SyncScheduler`, one task each, which waits for a network connection and retries up to three more times (30 s, 60 s, 120 s). On the next launch, any chosen Bible that never finished is queued again. iOS suspends apps in the background, so these downloads only progress while BibleLib is open.

Once a Bible is downloaded the reader, search, and everything else read only from Core Data — no network is needed.

### Theming

Colors live in `Assets.xcassets` (light and dark variants) and are exposed through `AppColors`; they match the palette used by the Android app. Standard controls take the app's orange as their tint, and system materials, fonts, and Dynamic Type are used throughout. The theme mode (System / Light / Dark) is stored by `ThemeManager` and applied at the app root.

---

## Getting started

### 1. Clone the repository

```bash
git clone git@github.com:SiroDevs/BibleLib.git
cd BibleLib
```

### 2. Open the project

```bash
open BibleLib.xcodeproj
```

Xcode resolves the Swift Package dependencies automatically. If it does not, use **File ▸ Packages ▸ Resolve Package Versions**.

### 3. Run the app

Select the `BibleLib` scheme and an iPhone or iPad simulator (iOS 16 or newer), then press **⌘R**.

The Debug configuration uses the bundle identifier `com.biblelib.stg` and a staging app icon, so it installs alongside a production build without conflict.

On first launch the app walks through Bible selection, then downloads the chosen translation(s) from the live content API. You need a network connection for this initial download — after that, reading, browsing, and searching that translation work fully offline.

### 4. Release builds (optional)

Release builds use the bundle identifier `com.biblelib`. Set your own signing team under **Signing & Capabilities**, then use **Product ▸ Archive** and distribute through the Organizer. This is not needed for development or contributing.

---

## Contributing

1. Fork the repository and create a feature branch off `develop`.
2. New screens belong in their own folder under `Feature/`, with `View/` and `ViewModel/` subfolders.
3. Use native SwiftUI controls — `List`, `Form`, `NavigationStack`, sheets, toolbars, and system fonts — rather than custom look-alikes of other platforms' components. Shared views go in `Core/Ui/Components`.
4. View models are `ObservableObject`s registered in `DependencyMap` and resolved through `DiContainer`. Logic that several features need goes in a repository under `Domain/Repos`. Keep view models small; move self-contained logic into its own type.
5. Open a pull request with a clear description and reference any related issue.

For questions, open a GitHub issue.

**License:** MIT — feel free to use, modify, and distribute.
