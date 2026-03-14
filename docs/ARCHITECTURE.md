# Architecture / Folder Conventions

This project follows a simple “clean-ish” structure to keep UI, state, and data access separated.

## Folder diagram

```text
lib/
  constants/     App-wide constants (colors, keys, etc.)
  models/        Plain data models (no Firebase/Flutter UI)
  providers/     State management (ChangeNotifier / ViewModel-style)
  screens/       Full pages (Scaffold, navigation, composition)
  services/      Firebase/HTTP/local IO access (no widget building)
  utils/         Small helpers (formatting, parsing, etc.)
  widgets/       Reusable UI components used by screens

assets/
  images/        Image assets
  map/           GeoJSON assets
```

## Naming conventions

- Files: `snake_case.dart`
- Types (classes, enums): `PascalCase`
- Members (vars, functions): `camelCase`

## Data flow rules (UI → State → Data)

- Screens/widgets should not call `FirebaseFirestore.instance`, `FirebaseAuth.instance`, or `FirebaseStorage.instance` directly.
- Providers orchestrate state and call services.
- Services own Firebase/HTTP/local storage details.
- Models represent app data (typed objects instead of loose maps when practical).

### Typed parsing boundary

- Prefer returning typed models from services (e.g., `ProgramInfo`, `OrganizationInfo`) instead of `Map<String, dynamic>`.
- Parse Firestore payloads at the service/model boundary (`fromMap` / `listFromDynamic`).
- Only serialize back to `Map<String, dynamic>` at persistence boundaries (writes/updates).

## Example: typed model + service

Model lives in `lib/models/`:

- `NewsItem` in `lib/models/news_item.dart`

Service lives in `lib/services/`:

- `NewsService.fetchAllNews()` in `lib/services/news/news_service.dart` returns `List<NewsItem>`.

UI usage lives in screens/widgets:

- `AllNewsPage` in `lib/screens/all_news_page.dart`
- `AutoImageSlider` in `lib/widgets/auto_image_slider.dart`

## Example: typed lookup service

- `ProgramLookupService` in `lib/services/map/program_lookup_service.dart` returns typed models:
  - `ProgramInfo` (`lib/models/program_info.dart`)
  - `OrganizationInfo` (`lib/models/organization_info.dart`)

## Example: typed map data record

- `ProgramBeneficiariesService` in `lib/services/map/program_beneficiaries_service.dart` reads/writes:
  - `ProgramBeneficiariesRecord` (`lib/models/program_beneficiaries_record.dart`)
- Rule: Keep Firestore documents as maps, but expose typed records to UI/services.

## Example: provider calling a service

Provider lives in `lib/providers/`:

- `AvailableApplicationsProvider` calls `AvailableApplicationsService` to load/cache data.

Rule of thumb:

- If it touches the network / Firebase → `services/`
- If it stores UI state / loading/error → `providers/`
- If it’s a data object → `models/`
- If it builds UI → `screens/` or `widgets/`
