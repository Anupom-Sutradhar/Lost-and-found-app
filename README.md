# UniFind — Lost and Found App

A secure and user-friendly mobile application for reporting and recovering lost items at Leading University.

**Project:** Project-1  
**Department:** Computer Science and Engineering (CSE)  
**Course Code:** 3240

## Features

- **University-only access:** Registration using `@lus.ac.bd` email addresses.
- **Email verification:** Verify accounts before posting items.
- **Lost and Found posts:** Browse lost and found items separately.
- **Photo upload:** Upload item images from the camera or gallery.
- **Search and filtering:** Search by item name and filter by category.
- **My Posts:** Edit, delete, and mark posts as resolved.
- **User profiles:** Manage student information and contact details.
- **Real-time messaging:** Communicate with other users about items.
- **Responsive UI:** A clean interface with Lost and Found color themes.

## Technology Stack

| Component | Technology |
|---|---|
| Framework | Flutter |
| Programming Language | Dart |
| Backend | Supabase |
| Database | PostgreSQL |
| Authentication | Supabase Auth |
| File Storage | Supabase Storage |
| State Management | Provider |
| Version Control | Git and GitHub |

## Requirements

Before running the project, install:

- Flutter SDK
- Android Studio and Android SDK
- Git
- A Supabase account

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/Anupom-Sutradhar/Lost-and-found-app.git
cd Lost-and-found-app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Supabase

1. Create a project at [Supabase](https://supabase.com/).
2. Configure the database tables, authentication, storage buckets, and Row Level Security policies.
3. Use the project's `supabase_setup.sql` file as a setup reference.
4. Configure the Supabase URL and publishable/anon key in the application as required by the source code.

**Security:** Never commit your Supabase `service_role` key, database password, or other private credentials to GitHub.

### 4. Run the Application

```bash
flutter run
```

## Project Structure

```text
lib/                    # Main Flutter source code
assets/                 # Images, icons, and other assets
android/                # Android-specific files
ios/                    # iOS-specific files
web/                    # Web platform files
windows/                # Windows platform files
linux/                  # Linux platform files
macos/                  # macOS platform files
pubspec.yaml            # Dependencies and project configuration
supabase_setup.sql      # Database setup SQL
messaging_migration.sql  # Messaging database migration
```

## Future Improvements

- AI-based lost and found item matching
- Push notifications
- Administrative dashboard
- Support for multiple universities
- Report generation and analytics

## Contributors

- **Anupom Sutradhar**
- **Dip Sutradhar**

## License

Add a license if you intend to distribute the project under an open-source license.
