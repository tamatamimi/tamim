# ERP Guides — Documentation Knowledge Base (Mobile)

An **offline-first**, **bilingual (Arabic/English)** Flutter application for
organizing and browsing ERP system documentation: written guides, visual
guides, procedures, data-flow diagrams, and use cases.

> Scope of this scaffold: a working, compilable project skeleton with a real
> data model, local SQLite storage, seeded sample content, search, and a
> bilingual RTL-aware UI — a foundation to build on, not a finished product.

---

## 1. Technology decisions & rationale

| Layer | Choice | Why |
|---|---|---|
| Framework | **Flutter** | One codebase (iOS/Android), mature **RTL/Arabic** support, strong media rendering, robust offline story. |
| Storage | **SQLite via `sqflite`** | Offline-first; content browsable and searchable with no connectivity. |
| Content | **Versioned JSON asset → SQLite import** | Update guides by shipping a new JSON version; no code change to add/edit content. |
| Search | **FTS5 (prefix + ranked), LIKE fallback** | Fast bilingual full-text search; degrades gracefully where FTS5 is absent. |
| Rendering | **`flutter_markdown`** | Renders written guides, procedures, and text of diagrams/use cases. |
| Media | **`video_player`+`chewie`, `pdfx`** | In-app video and PDF viewing for visual guides; asset/file/network sources. |
| State | **`provider`** | Language, theme, and favorites; swap for Riverpod/Bloc as complexity grows. |
| i18n | **`flutter_localizations` + string table** | Automatic RTL/LTR from active locale. |

**Why offline-first:** procedural ERP documentation is consulted *during*
execution (field, branch, floor) where connectivity is unreliable. Local
storage makes the content a dependable operational reference, not a
network-bound convenience.

## 2. Architecture

```
lib/
├── main.dart                 # Entry point + Provider wiring
├── app.dart                  # MaterialApp, theming, localization, RTL
├── core/
│   ├── state/                # AppState (language + theme)
│   ├── localization/         # AppStrings (AR/EN table)
│   └── theme/                # Theme + icon mapping
├── data/
│   ├── models/               # Category, Guide, GuideType
│   ├── database/             # DatabaseHelper (SQLite) + SeedData
│   └── repositories/         # GuideRepository (single data access point)
└── presentation/
    ├── screens/              # Home, Category, GuideDetail, Search
    └── widgets/              # GuideCard, TypeBadge
```

**Layering principle:** the UI depends on `GuideRepository`, never on sqflite
directly. Swapping the storage engine — or adding a backend sync later — is a
repository-only change, with zero UI rewrite.

## 3. Data model

- **Category** — an ERP module/domain (Finance, HR, Inventory…).
- **Guide** — a documentation item with a **`GuideType`** of
  `written · visual · procedure · dataFlow · useCase`, bilingual title /
  summary / Markdown content, tags, an optional image/diagram asset, and a
  last-updated date.

## 4. Getting started

```bash
cd erp_guides_app
flutter pub get
flutter run          # device/emulator
flutter test         # unit tests
flutter analyze      # static analysis
```

> Flutter SDK ≥ 3.0 required. This environment has no Flutter toolchain, so the
> project ships hand-authored and unbuilt — run the commands above locally to
> fetch dependencies and launch.

## 5. Roadmap (evolving beyond the offline MVP)

| Phase | Capability | Status |
|---|---|---|
| 1 | Offline catalogue, bilingual UI, search, seeded content | ✅ Done |
| 2 | Content import (versioned JSON), FTS5 search, favorites | ✅ Done |
| 3 | In-app video player + PDF/image viewers for visual guides | ✅ Done |
| 4 | Backend sync (Supabase/Postgres or **Oracle DB + ORDS**) | Repository-layer swap; central authoring & governance |
| 5 | Auth, role-based access, audit trail | Aligns with least-privilege / SoD controls |

### Media attachments (Phase 3)

Each guide may carry one media attachment via `media_type`
(`image` · `video` · `pdf`) and `media_source`. The source is resolved
automatically as **asset**, **local file**, or **network** URL, so the same
field works for bundled offline media and online content. `GuideMediaView`
dispatches to the right viewer; any load failure degrades to a calm error box
so the guide text stays readable. A sample PDF ships at
`assets/media/sample_procedure.pdf`; the visual guide references a sample
network video (swap for a bundled file for fully offline use).

### Content update workflow (Phase 2)

Content lives in `assets/content/guides.json` with a top-level `contentVersion`.
On launch, `ContentImporter` compares that version with the version stored in
the `meta` table and re-imports only when they differ — then rebuilds the FTS5
index. To publish updated documentation: **edit the JSON, bump
`contentVersion`, ship the build.** No schema or code change required. When the
backend arrives (Phase 4), the same importer fetches the JSON from the server
instead of the bundle — the rest of the pipeline is unchanged.

## 6. Governance considerations

- **Data sovereignty:** offline SQLite keeps operational documentation on-device;
  any future backend should be self-hostable (Postgres/Oracle) to satisfy
  institutional compliance.
- **Content lifecycle:** each guide carries a last-updated date — extend with
  version/owner/review-cycle fields for accreditation-ready documentation.
- **Least privilege:** the roadmap's role-based access enforces Segregation of
  Duties when authoring moves from seeded content to live editing.
