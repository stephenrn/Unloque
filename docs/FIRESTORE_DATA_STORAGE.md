# Firestore Data Storage (Unloque)

This document describes how **Unloque** stores data in **Cloud Firestore**, and what the admin tooling (“Developer Options” and organization admin features) reads/writes.

It is intended to help the developer of the **admin web app** implement compatible reads/writes without changing the existing mobile app behavior.

## Table of contents

- [1. Conventions & identifiers](#1-conventions--identifiers)
- [2. Collections overview](#2-collections-overview)
- [3. `organizations` collection](#3-organizations-collection)
  - [3.1 Organization document](#31-organization-document)
  - [3.2 `programs` subcollection](#32-programs-subcollection)
  - [3.3 `news` subcollection](#33-news-subcollection)
- [4. `users` collection](#4-users-collection)
  - [4.1 User document](#41-user-document)
  - [4.2 `users-application` subcollection](#42-users-application-subcollection)
  - [4.3 `notifications` subcollection](#43-notifications-subcollection)
- [5. `mapdata` collection](#5-mapdata-collection)
  - [5.1 Beneficiary documents (`type == beneficiaries`)](#51-beneficiary-documents-type--beneficiaries)
  - [5.2 Quezon population document (`mapdata/quezon_population`)](#52-quezon-population-document-mapdataquezon_population)
- [6. Nested schema reference](#6-nested-schema-reference)
  - [6.1 `detailSections` (program details sections)](#61-detailsections-program-details-sections)
  - [6.2 `formFields` (program application form template)](#62-formfields-program-application-form-template)
  - [6.3 Submitted application `formFields` (user answers)](#63-submitted-application-formfields-user-answers)
  - [6.4 `organizationResponse` (organization response to a user)](#64-organizationresponse-organization-response-to-a-user)
- [7. Admin behaviors (“Developer Options” + Org admin)](#7-admin-behaviors-developer-options--org-admin)
  - [7.1 Create organization](#71-create-organization)
  - [7.2 Delete organization data](#72-delete-organization-data)
  - [7.3 Create program](#73-create-program)
  - [7.4 Delete program + cascade](#74-delete-program--cascade)
  - [7.5 Update program details/form](#75-update-program-detailsform)
  - [7.6 Upsert/delete news](#76-upsertdelete-news)
  - [7.7 Respond to a user application](#77-respond-to-a-user-application)
  - [7.8 Edit Quezon population](#78-edit-quezon-population)
  - [7.9 Manage mapdata docs per organization](#79-manage-mapdata-docs-per-organization)
- [8. Query patterns for the admin web app](#8-query-patterns-for-the-admin-web-app)
- [9. Gotchas & data quality notes](#9-gotchas--data-quality-notes)
- [10. Example documents](#10-example-documents)

---

## 1. Conventions & identifiers

These conventions are embedded into the current Flutter app services and should be treated as canonical.

### IDs

- **Organization ID (`organizationId`)**
  - Firestore path: `organizations/{organizationId}`
  - The document ID is treated as the primary identifier.
  - The organization document also stores a duplicate `id` field.

- **Program ID (`programId`)**
  - Firestore path: `organizations/{organizationId}/programs/{programId}`
  - The document ID is treated as the primary identifier.
  - The program document also stores a duplicate `id` field.

- **Application ID (`applicationId`)**
  - Firestore path: `users/{uid}/users-application/{applicationId}`
  - In the current app, `applicationId` is effectively the **program ID**.
  - The application doc stores a duplicate `id` field that is also the program ID.

### Timestamps

- `createdAt`
  - Often written as `FieldValue.serverTimestamp()` (server-side) for orgs/programs/user-apps/news.
  - In user profiles it is written as `Timestamp.now()` (client-side).

- `lastUpdated`
  - Written to program docs when editing details/form.

- `timestamp`
  - Used for notifications ordering.

### Storage (Firebase Storage)

This doc is Firestore-focused, but admin deletion routines also delete Storage folders.

- Org program assets (admin deletes these): `organizations/{orgId}/programs/{programId}/...`
- Org folder (admin deletes this): `organizations/{orgId}/...`
- User-uploaded attachments for applications: `users/{uid}/applications/{applicationId}/{fieldLabel}/{timestamp_filename}`

---

## 2. Collections overview

Top-level collections used by the app:

- `organizations`
  - Subcollections: `programs`, `news`
- `users`
  - Subcollections: `users-application`, `notifications`
- `mapdata`
  - Contains multiple “types” of documents:
    - beneficiary distribution docs (`type: "beneficiaries"`)
    - a single fixed doc: `mapdata/quezon_population`

---

## 3. `organizations` collection

### 3.1 Organization document

Path:

- `organizations/{organizationId}`

Fields written by the app:

| Field | Type | Notes |
|---|---:|---|
| `id` | string | Duplicate of doc id |
| `name` | string | Display name |
| `logoUrl` | string | Image URL used by UI |
| `website` | string | Organization website |
| `createdAt` | timestamp | `serverTimestamp()` |

Primary writer:

- `DeveloperOptionsService.createOrganization(...)`

### 3.2 `programs` subcollection

Path:

- `organizations/{organizationId}/programs/{programId}`

Core fields written on create:

| Field | Type | Notes |
|---|---:|---|
| `id` | string | Duplicate of doc id |
| `name` | string | Program name |
| `category` | string | Category filter key |
| `deadline` | string | Stored as string (see gotchas) |
| `color` | int | ARGB color value (Flutter `Color.value`) |
| `organizationId` | string | Duplicate of parent org id |
| `programStatus` | string | Typically `"Open"` or `"Closed"` |
| `createdAt` | timestamp | `serverTimestamp()` |

Additional fields written on update:

| Field | Type | Notes |
|---|---:|---|
| `detailSections` | array | List of maps; see [6.1](#61-detailsections-program-details-sections) |
| `formFields` | array | List of maps; see [6.2](#62-formfields-program-application-form-template) |
| `lastUpdated` | timestamp | `serverTimestamp()` |

Primary writers/readers:

- Create: `OrganizationProgramsService.createProgram(...)`
- List: `OrganizationProgramsService.programsStream(...)`
- Load editor data: `ProgramEditorService.loadDetailSections(...)`, `ProgramEditorService.loadFormFields(...)`
- Save editor data: `ProgramEditorService.updateProgram(...)`
- Public listings: `AvailableApplicationsService` reads `programStatus == "Open"`

### 3.3 `news` subcollection

Path:

- `organizations/{organizationId}/news/{newsId}`

Fields used by UI (read + written by admin):

| Field | Type | Notes |
|---|---:|---|
| `headline` | string | Title |
| `category` | string | Category label |
| `date` | string | Used for sorting (`orderBy('date')`) |
| `imageUrl` | string | Card image URL |
| `newsUrl` | string | External link |
| `createdAt` | timestamp | Set on *both* create and update (see gotchas) |

Primary writers/readers:

- `OrganizationNewsService.upsertNews(...)`
- `OrganizationNewsService.deleteNews(...)`
- `NewsService.fetchAllNews()`

---

## 4. `users` collection

### 4.1 User document

Path:

- `users/{uid}`

Fields written by the app:

| Field | Type | Notes |
|---|---:|---|
| `uid` | string | Duplicate of doc id |
| `email` | string | From auth provider |
| `username` | string | Display name |
| `photoUrl` | string? | Profile image URL |
| `createdAt` | timestamp | Client-side `Timestamp.now()` |
| `lastLogin` | timestamp | Client-side `Timestamp.now()` |
| `phone` | string | Optional; set by profile edit |
| `address` | string | Optional; set by profile edit |

Primary writers/readers:

- `UserProfileService.createUserProfile(...)`
- `UserProfileService.ensureUidAndTrackLogin(...)`
- `UserProfileService.updateProfile(...)`

### 4.2 `users-application` subcollection

Path:

- `users/{uid}/users-application/{applicationId}`

This is the **user’s application per program**, and `applicationId` is treated as **program ID**.

Minimum fields written when a user starts an application:

| Field | Type | Notes |
|---|---:|---|
| `id` | string | Program ID |
| `status` | string | Defaults to `"Ongoing"` |
| `createdAt` | timestamp | `serverTimestamp()` |

Additional fields written during user flow:

| Field | Type | Notes |
|---|---:|---|
| `formFields` | array | Submitted answers; see [6.3](#63-submitted-application-formfields-user-answers) |
| `organizationResponse` | map | Org response; see [6.4](#64-organizationresponse-organization-response-to-a-user) |

Primary writers/readers:

- Create shell doc: `UserApplicationService.createUserApplication(...)`
- Save form answers: `ApplicationFormService.saveFormFields(...)`
- Update status: `ApplicationFormService.updateStatus(...)` and `OrganizationResponseService.sendResponse(...)`
- Admin reads: `AdminApplicationService.fetchApplicationsForProgram(...)`

### 4.3 `notifications` subcollection

Path:

- `users/{uid}/notifications/{notificationId}`

This app uses notifications to alert users that an organization responded.

Fields written by the app:

| Field | Type | Notes |
|---|---:|---|
| `title` | string | E.g. `"Response Received"` |
| `message` | string | Human-readable |
| `type` | string | E.g. `"response"` |
| `programId` | string | Program id or fallback |
| `programName` | string | Display |
| `organizationId` | string | Org id |
| `organizationName` | string | Display |
| `applicationId` | string | The `users-application` doc id |
| `isRead` | bool | Default false |
| `timestamp` | timestamp | `serverTimestamp()` |

Primary writers/readers:

- Write (on response): `OrganizationResponseService.sendResponse(...)`
- Read streams: `NotificationService.notificationsStream(...)` / `unreadNotificationsStream(...)`
- Mark read/delete: `NotificationService.markAllAsRead/markAsRead/deleteNotification`

---

## 5. `mapdata` collection

The `mapdata` collection is used for map/analytics data and a Quezon population dataset.

### 5.1 Beneficiary documents (`type == beneficiaries`)

Path:

- `mapdata/{docId}` where document content includes `type: "beneficiaries"`

Fields (as used by the app):

| Field | Type | Notes |
|---|---:|---|
| `type` | string | Must be `"beneficiaries"` for the app’s filters |
| `programId` | string | Program id |
| `programName` | string | Display |
| `organizationId` | string | Owning org |
| `title` | string | Display title |
| `Total Beneficiaries` | number | Note the **space** in the key |
| `{municipalityName}` | number | One field per municipality (dynamic keys) |
| `updatedAt` | timestamp | Set when saving via service |
| `createdAt` | timestamp? | Not consistently written by current code |

Primary writers/readers:

- Write: `ProgramBeneficiariesService.save(...)` (adds `updatedAt`)
- Read: `MapDataService.beneficiaryDocsStream()` and `fetchBeneficiaryRecords()`
- Org filtered list: `OrganizationMapDataService.organizationMapDataStream(...)`

### 5.2 Quezon population document (`mapdata/quezon_population`)

Path:

- `mapdata/quezon_population`

Fields:

- This is a single document containing **municipality names as keys** and **population values as integers**.
- Example keys include: `"Lucena City"`, `"Tayabas City"`, and a special key `"Total Population"`.

Primary writers/readers:

- `QuezonPopulationService.load()` / `QuezonPopulationService.save(...)`

---

## 6. Nested schema reference

### 6.1 `detailSections` (program details sections)

Stored on program docs at:

- `organizations/{orgId}/programs/{programId}.detailSections`

Type:

- `List<Map<String, dynamic>>`

Each section is a polymorphic record with:

| Field | Type | Notes |
|---|---:|---|
| `id` | string | Stable identifier used by editor |
| `type` | string | One of: `paragraph`, `list`, `attachment` |
| `label` | string | Section heading label |

Per-type payload:

- `type: "paragraph"`
  - `content: string`

- `type: "list"`
  - `items: string[]`

- `type: "attachment"`
  - `files: { name: string, downloadUrl?: string, uploadedAt?: string }[]`

Notes:

- The editor/UI may use extra transient keys locally (e.g. `path`, `isPending`) but the persisted shape should stay minimal.

### 6.2 `formFields` (program application form template)

Stored on program docs at:

- `organizations/{orgId}/programs/{programId}.formFields`

Type:

- `List<Map<String, dynamic>>`

Common keys:

| Field | Type | Notes |
|---|---:|---|
| `id` | string | Often numeric-like but stored as string |
| `type` | string | One of: `short_answer`, `paragraph`, `multiple_choice`, `checkbox`, `date`, `attachment` |
| `label` | string | Prompt text |
| `required` | bool | Defaults to `true` if missing |

Optional keys:

- `options: string[]` (used by `multiple_choice` and `checkbox`)
- `placeholder: string` (used for text fields)

### 6.3 Submitted application `formFields` (user answers)

Stored on user application docs at:

- `users/{uid}/users-application/{applicationId}.formFields`

Type:

- `List<Map<String, dynamic>>`

Important: submitted field entries reuse the **template keys** (`id`, `type`, `label`, `required`, `options`, `placeholder`) and add **answer payload**.

Per type, the app expects these additional keys:

- `short_answer` / `paragraph`
  - `answer: string`

- `multiple_choice`
  - `selectedOption: string`

- `checkbox`
  - `selectedOptions: string[]`

- `date`
  - `selectedDate: string` (ISO-8601 string; parsed via `DateTime.tryParse`)

- `attachment`
  - `files: { name: string, downloadUrl: string }[]`

Attachment notes:

- Actual file bytes live in Firebase Storage.
- Firestore stores only metadata (`name`, `downloadUrl`).

### 6.4 `organizationResponse` (organization response to a user)

Stored on user application docs at:

- `users/{uid}/users-application/{applicationId}.organizationResponse`

Type:

- `Map<String, dynamic>`

Fields written by the app:

| Field | Type | Notes |
|---|---:|---|
| `organizationId` | string | Required |
| `userId` | string | Required |
| `applicationId` | string | Required |
| `responseSections` | array | Same shape as program `detailSections` (persisted form) |
| `createdAt` | timestamp | `serverTimestamp()` |

Also written alongside the response:

- `status` is set to `"Completed"` on the user’s application doc.

---

## 7. Admin behaviors (“Developer Options” + Org admin)

This section is written from the perspective of **what the existing Flutter admin UI does**, so the admin web app can match behavior.

### 7.1 Create organization

Implementation behavior:

- Generates a new Firestore doc id: `FirebaseFirestore.instance.collection('organizations').doc().id`
- Writes `organizations/{orgId}` with fields: `id`, `name`, `logoUrl`, `website`, `createdAt`.

### 7.2 Delete organization data

Implementation behavior (current app):

1. Loads all programs under `organizations/{orgId}/programs`.
2. For each program doc:
   - Deletes the program document.
   - Schedules deletion of the Storage folder: `organizations/{orgId}/programs/{programId}`.
3. Deletes the organization doc `organizations/{orgId}`.
4. Recursively deletes the program folders.
5. Recursively deletes the organization folder `organizations/{orgId}`.

Important limitations (what is **not** deleted by this routine):

- `organizations/{orgId}/news/*`
- Any `mapdata` docs for that org (`mapdata` is not cascaded here)
- User application docs under `users/*/users-application/*` (unless separately cleaned up)
- User notifications

If the admin web app provides “delete organization”, decide explicitly whether to preserve this behavior or perform a more complete cascade.

### 7.3 Create program

Implementation behavior:

- Creates `organizations/{orgId}/programs/{newId}` and sets:
  - `id`, `name`, `category`, `deadline`, `color`, `organizationId`, `programStatus`, `createdAt`.

### 7.4 Delete program + cascade

Implementation behavior:

1. Deletes `organizations/{orgId}/programs/{programId}`.
2. Fetches *all* users from `users`.
3. For each user:
   - Queries `users/{uid}/users-application` where `id == programId`.
   - Deletes matching application docs.

Important limitations:

- Does not delete Firebase Storage uploads for user attachments.
- Does not delete user notifications.
- Does not delete `mapdata` beneficiary docs for that program.

### 7.5 Update program details/form

Implementation behavior:

- Updates an existing program doc with the provided `programData` plus:
  - `lastUpdated: serverTimestamp()`

In practice this is used to store:

- `detailSections`: list of detail section maps
- `formFields`: list of form field maps

### 7.6 Upsert/delete news

Implementation behavior:

- **Create**: `add(...)` a new doc in `organizations/{orgId}/news`.
- **Update**: `update(...)` an existing doc.
- In both cases it writes `createdAt: serverTimestamp()`.

Delete behavior:

- `delete()` the specific news doc.

### 7.7 Respond to a user application

Implementation behavior:

- Updates user application doc:
  - Sets `organizationResponse` map (including `responseSections`)
  - Sets `status` to `"Completed"`
- Adds a new user notification doc in `users/{uid}/notifications` with:
  - `title`, `message`, `type`, program/org identifiers, `isRead: false`, `timestamp`, `applicationId`.

### 7.8 Edit Quezon population

Implementation behavior:

- Reads: `mapdata/quezon_population`
- Writes: merges numeric values into `mapdata/quezon_population` (does not overwrite other fields).

### 7.9 Manage mapdata docs per organization

Implementation behavior:

- Lists: queries `mapdata` where `organizationId == {orgId}`.
- Deletes: deletes a single `mapdata/{docId}`.

---

## 8. Query patterns for the admin web app

These are the patterns currently used (or implied) by the Flutter app.

### Organizations

- List all orgs:
  - `organizations` (stream)

### Programs

- List programs for org:
  - `organizations/{orgId}/programs` (stream)

- Fetch program details for editing:
  - `organizations/{orgId}/programs/{programId}`

### News

- List news for org:
  - `organizations/{orgId}/news` ordered by `date` descending

### Applications per program (admin view)

Current approach in the codebase:

- Stream all users: `users`.
- For each user, query: `users/{uid}/users-application` where `id == programId`.

Notes:

- This is expensive at scale but matches current behavior.
- A possible alternative (not used by the app) is a `collectionGroup('users-application')` query, but it depends on security rules and indexing.

### Notifications

- List user notifications:
  - `users/{uid}/notifications` ordered by `timestamp` desc

---

## 9. Gotchas & data quality notes

- **Dates are strings** in multiple places (`deadline`, news `date`, submitted `selectedDate`).
  - `orderBy('date')` only works correctly if the string format sorts lexicographically (e.g. ISO `YYYY-MM-DD`).

- **`createdAt` on news is overwritten on update**.
  - `OrganizationNewsService.upsertNews` sets `createdAt` on both add and update.
  - If you need true created-vs-updated timestamps, add a new `updatedAt` field and keep `createdAt` stable (would require app changes).

- **`mapdata` uses a field with spaces**: `"Total Beneficiaries"`.
  - Keep the key exact; do not rename in admin tooling unless you migrate data.

- **Colors are stored as ints**.
  - In Firestore: `color` is an integer (ARGB).
  - The UI wraps it into `Color(colorValue)`.

- **Program form fields default `required` to true** when missing.

- **Cascade deletes are partial** (by current implementation).
  - Deleting an organization does not delete everything related to it.
  - Deleting a program cleans up user application docs but not Storage uploads or mapdata.

---

## 10. Example documents

### Organization

```json
// organizations/{organizationId}
{
  "id": "org_abc123",
  "name": "DOST-SEI",
  "logoUrl": "https://...",
  "website": "https://...",
  "createdAt": "<server timestamp>"
}
```

### Program

```json
// organizations/{organizationId}/programs/{programId}
{
  "id": "prog_xyz789",
  "name": "Undergraduate Scholarship",
  "category": "Education",
  "deadline": "2026-06-30",
  "color": 4283215696,
  "organizationId": "org_abc123",
  "programStatus": "Open",
  "createdAt": "<server timestamp>",
  "lastUpdated": "<server timestamp>",
  "detailSections": [
    {
      "id": "section_1",
      "type": "paragraph",
      "label": "Description",
      "content": "..."
    },
    {
      "id": "section_2",
      "type": "list",
      "label": "Requirements",
      "items": ["Requirement A", "Requirement B"]
    },
    {
      "id": "section_3",
      "type": "attachment",
      "label": "Downloadable Forms",
      "files": [
        {"name": "Form.pdf", "downloadUrl": "https://..."}
      ]
    }
  ],
  "formFields": [
    {
      "id": "1",
      "type": "short_answer",
      "label": "Full name",
      "required": true,
      "placeholder": "Juan Dela Cruz"
    },
    {
      "id": "2",
      "type": "attachment",
      "label": "Upload your ID",
      "required": true
    }
  ]
}
```

### User application

```json
// users/{uid}/users-application/{applicationId}
{
  "id": "prog_xyz789",
  "status": "Ongoing",
  "createdAt": "<server timestamp>",
  "formFields": [
    {
      "id": "1",
      "type": "short_answer",
      "label": "Full name",
      "required": true,
      "answer": "Juan Dela Cruz"
    },
    {
      "id": "2",
      "type": "attachment",
      "label": "Upload your ID",
      "required": true,
      "files": [
        {"name": "id.png", "downloadUrl": "https://..."}
      ]
    }
  ],
  "organizationResponse": {
    "organizationId": "org_abc123",
    "userId": "uid_123",
    "applicationId": "prog_xyz789",
    "createdAt": "<server timestamp>",
    "responseSections": [
      {
        "id": "resp_1",
        "type": "paragraph",
        "label": "Decision",
        "content": "Approved"
      }
    ]
  }
}
```

### Notification

```json
// users/{uid}/notifications/{notificationId}
{
  "title": "Response Received",
  "message": "Organization DOST-SEI has responded to your application for Undergraduate Scholarship",
  "type": "response",
  "programId": "prog_xyz789",
  "programName": "Undergraduate Scholarship",
  "organizationId": "org_abc123",
  "organizationName": "DOST-SEI",
  "applicationId": "prog_xyz789",
  "isRead": false,
  "timestamp": "<server timestamp>"
}
```

### Beneficiary mapdata doc

```json
// mapdata/{docId} (type == beneficiaries)
{
  "type": "beneficiaries",
  "programId": "prog_xyz789",
  "programName": "Undergraduate Scholarship",
  "organizationId": "org_abc123",
  "title": "Education - Undergraduate Scholarship",
  "Total Beneficiaries": 1200,
  "Lucena City": 100,
  "Tayabas City": 80,
  "updatedAt": "<server timestamp>"
}
```

### Quezon population

```json
// mapdata/quezon_population
{
  "Total Population": 1950000,
  "Lucena City": 278924,
  "Tayabas City": 112658
}
```
