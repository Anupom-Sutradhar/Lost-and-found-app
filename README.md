# UniFind 🔎

**A Secure and User-Friendly Mobile Application for Lost Item Reporting and Recovery**

Leading University — Department of CSE — Project-1 (Course Code: 3240)

---

## ✨ Features

- 🔐 **University-only access** — only `@lus.ac.bd` emails can register
- ✅ **Email verification** required before posting
- 📸 **Photo upload** — camera or gallery, stored in Supabase Storage
- 🏷️ **Lost / Found tabs** with category filtering
- 🔍 **Real-time search** by item name (case-insensitive)
- 📌 **My Posts** — edit, delete, mark resolved
- 👤 **Profile** with student ID, department, phone
- 🎨 **Colorful aesthetic design** — coral for Lost, mint for Found
- 📱 **Fully responsive** Android app

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x |
| Language | Dart |
| Backend | **Supabase** (Postgres + Auth + Storage + Realtime) |
| State Mgmt | Provider |
| Design | Material 3 + custom theme |

---

## 📋 Prerequisites

Install these on your machine first:

1. **Flutter SDK** (3.10 or newer) — https://docs.flutter.dev/get-started/install
2. **Android Studio** with Android SDK
3. **A Supabase account** (free) — https://supabase.com

Verify Flutter:
```bash
flutter doctor
```

---

## 🚀 Step-by-Step Setup

### Step 1: Create a Supabase project

1. Go to https://app.supabase.com → **New project**.
2. Name it `unifind`, choose a strong DB password (save it somewhere), and pick the closest region (e.g., **Singapore** for Bangladesh).
3. Wait ~2 minutes for it to provision.

### Step 2: Run the SQL setup

1. Open your Supabase project → **SQL Editor** (sidebar).
2. Click **+ New query**.
3. Open `supabase_setup.sql` from this project, copy the entire file.
4. Paste into the SQL Editor → click **Run**.

This creates:
- `profiles` and `posts` tables
- Row-Level Security policies (so users can only edit their own data)
- A trigger that auto-creates a profile when someone signs up
- A trigram index for fast search
- Realtime publication for live feed updates

### Step 3: Create Storage buckets

In Supabase dashboard → **Storage** → **New bucket**:

1. Bucket name: `post-images` → make it **Public** → Create
2. Bucket name: `profile-images` → make it **Public** → Create

Then go back to **SQL Editor** and run the **STORAGE POLICIES** section that's already in `supabase_setup.sql` (you can run the whole file again — it's idempotent, won't break anything).

### Step 4: Configure Authentication

In **Authentication → Providers**:
- **Email** is enabled by default. Keep "Confirm email" **ON**.

In **Authentication → URL Configuration**:
- Add this to **Redirect URLs**:
  ```
  io.supabase.unifind://login-callback/
  ```

### Step 5: Get your project keys

Go to **Project Settings → API** and copy:
- **Project URL** (looks like `https://xxxxx.supabase.co`)
- **anon / public key** (a long string starting with `eyJ...`)

### Step 6: Paste keys into the Flutter app

Open `lib/config/constants.dart` and replace:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

with your actual values.

If you're not at LUS, also change:
```dart
static const String universityEmailDomain = 'lus.ac.bd';
```
…and update the same domain inside `supabase_setup.sql` (search for `lus.ac.bd`), then re-run that SQL block.

### Step 7: Install Flutter dependencies

```bash
flutter pub get
```

### Step 8: Run the app! 🎉

1. Connect Android phone (USB debugging on), or start an emulator.
2. From Android Studio click ▶️, **or** terminal:
   ```bash
   flutter run
   ```

Sign up with a `@lus.ac.bd` email, click the verification link in your inbox, come back to the app — you're in.

---

## 📁 Project Structure

```
UniFind/
├── lib/
│   ├── main.dart                  # App entry, Supabase init
│   ├── config/
│   │   ├── constants.dart         # ← Put Supabase URL + key here
│   │   ├── routes.dart
│   │   └── theme.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   └── post_model.dart
│   ├── services/
│   │   ├── auth_service.dart      # Supabase Auth
│   │   ├── db_service.dart        # Postgres CRUD + streams
│   │   └── storage_service.dart   # Image upload
│   ├── providers/
│   │   └── auth_provider.dart
│   ├── widgets/
│   │   ├── gradient_button.dart
│   │   ├── post_card.dart         # Signature ribbon card
│   │   ├── status_badge.dart
│   │   └── empty_state.dart
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── auth/                  # login, signup, verify
│   │   ├── home/                  # feed, search, my posts, shell
│   │   ├── post/                  # create, detail
│   │   └── profile/               # profile, edit
│   └── utils/
│       ├── validators.dart
│       └── date_helpers.dart
├── android/                       # Android-specific config
├── pubspec.yaml
├── supabase_setup.sql             # ← Run this in Supabase SQL editor
└── README.md
```

---

## 🎨 Design System

| Token | Hex | Use |
|---|---|---|
| Coral | `#FF6B6B` | Lost items, primary CTA |
| Mint | `#4ECDC4` | Found items, secondary actions |
| Sunny | `#FFD93D` | Categories, accents |
| Lavender | `#A78BFA` | Profile, info tiles |
| Navy | `#1A1A2E` | Headings, body text |
| Cream | `#FFF9F0` | App background |

**Typography:** Poppins (display) + Inter (body) via google_fonts.

**Signature element:** every post card has a diagonal gradient ribbon on the top-left — coral for Lost, mint for Found. You see the type instantly while scrolling.

---

## 🗂 Database Schema

### `profiles` table
| Column | Type | Notes |
|---|---|---|
| id | uuid (PK) | FK → auth.users(id) |
| email | text | unique |
| name | text | |
| student_id | text | |
| department | text | nullable |
| phone | text | nullable |
| photo_url | text | nullable |
| created_at | timestamptz | default now() |

### `posts` table
| Column | Type | Notes |
|---|---|---|
| id | uuid (PK) | default `gen_random_uuid()` |
| user_id | uuid | FK → profiles(id) |
| user_name | text | snapshot at post time |
| user_photo_url | text | nullable |
| type | enum | `lost` \| `found` |
| status | enum | `active` \| `resolved` |
| title | text | |
| description | text | |
| image_url | text | nullable |
| location | text | |
| contact_info | text | |
| category | text | |
| created_at | timestamptz | default now() |
| resolved_at | timestamptz | nullable |

### Indexes
- `(type, status, created_at desc)` — main feed query
- `(user_id, created_at desc)` — My Posts
- GIN trigram on `title` — fast `ilike` search

### Security
All tables have RLS enabled. Policies enforce:
- Any signed-in (verified) user can **read** all posts and profiles
- Users can **insert / update / delete** only their own rows
- Image folders in storage are namespaced by user id → users can only write to their own folder

---

## ❗ Troubleshooting

**"Could not find supabase URL/key"**
→ You forgot to update `lib/config/constants.dart` with real values.

**Signup works but profile is empty / fails**
→ Make sure you ran the **entire** `supabase_setup.sql` (specifically the `handle_new_user` trigger).

**"Email rate limit exceeded"**
→ Supabase free tier sends ~3 emails/hour by default. Wait an hour, or set up a custom SMTP in **Auth → Email Templates**.

**Image upload returns 403 / "new row violates RLS"**
→ Make sure you created both Storage buckets and set them to **Public**, and ran the storage policies SQL.

**Email verification deeplink doesn't open the app**
→ Make sure the redirect URL in Supabase dashboard exactly matches `io.supabase.unifind://login-callback/` and the AndroidManifest's intent filter scheme is `io.supabase.unifind`.

**"The query requires a configuration"**
→ Run `supabase_setup.sql` again — extensions like `pg_trgm` need to be created.

---

## 📅 Work Plan (from proposal)

- ✅ **Week 1** — Requirement analysis, UI design, Supabase setup
- ✅ **Week 2** — Authentication, university email validation
- ✅ **Week 3** — Lost & Found posting, image upload
- ✅ **Week 4** — Post management, search & filter
- 🟡 **Week 5** — Final testing, bug fixing, documentation

---

## 👥 Team

| Name | ID |
|---|---|
| Anupom Sutradhar | 0182320012101059 |
| Dip Sutra Dhar | 0182320012101090 |

**Supervisor:** Kazi Md. Jahid Hasan, Assistant Professor & Head, Dept. of CSE

---

Made with ❤️ at Leading University, Sylhet.
#   u n i f i n d - l o s t - a n d - f o u n d - a p p  
 #   L o s t - a n d - f o u n d - a p p  
 