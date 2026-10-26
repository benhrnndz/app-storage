# Student LMS & Academic Portfolio

> A student-centric Learning Management System, Coursework Storage, and Class Schedule Manager built with **Flutter** for cross-platform mobile and web environments. Developed for **System Integration and Architecture**.

---

## 📌 Project Overview
Unlike institutional LMS platforms that primarily serve administrative grading and faculty workflows, this application is engineered with a **user-first approach for students**. It serves as:
1. **Academic Portfolio & Coursework Storage**: Cataloging activities, presentations, and software projects—complete with direct links to code repositories (GitHub/GitLab) and video demonstrations (YouTube/Drive/Loom).
2. **Weekly Timetable & Dedicated Calendar**: Providing a semester timetable with an opt-in calendar sync mechanism where students decide which classes populate their active agenda.
3. **Cross-Device Cloud Synchronization** *(Phase 3)*: Google Sign-In and cloud persistence so coursework and schedules remain accessible across all student devices.
4. **AI Academic Assistant** *(Phase 5)*: Context-aware advice, study scheduling, and task realignment.

---

## 🏛️ System Architecture

The application adopts a **Feature-First Layered Architecture** emphasizing loose coupling, high cohesion, and domain immutability.

```
lib/
├── models/                     # Domain Layer: Pure Dart entity models & serialization
│   ├── course.dart             # Course definition (id, code, title, instructor, semester)
│   ├── deliverable.dart        # Deliverables (activities, projects with repo & demo URLs)
│   └── schedule.dart           # Weekly schedule slots with calendar sync flag
├── data/                       # Data Layer: Mock fixtures & upcoming repository implementations
│   └── mock_data.dart          # Local mock data for development and testing
├── features/                   # Presentation Layer: Feature-based modular UI
│   ├── navigation/             # Main navigation shell (IndexedStack, NavigationBar)
│   ├── courses/                # Course catalog, details, deliverable tiles
│   │   ├── screens/            # CoursesScreen, CourseDetailsScreen
│   │   └── widgets/            # CourseCard, DeliverableTile
│   ├── schedule/               # Schedule & calendar views
│   │   └── screens/            # ScheduleScreen (Agenda View & Timetable Settings)
│   ├── auth/                   # [Phase 3] Google Authentication & user session
│   └── ai_assistant/           # [Phase 5] LLM Assistant integration
└── main.dart                   # Application bootstrap and Material 3 theme configuration
```

---

## 🚦 Roadmap & Implementation Status

| Milestone | Description | Status |
| :--- | :--- | :---: |
| **Phase 1: Environment & Toolchain** | Flutter SDK 3.47+, CocoaPods, Xcode toolchain, VS Code setup | ✅ Completed |
| **Phase 2: Domain Data Modeling** | `Course`, `Deliverable`, `ScheduleSlot` entities with unit tests | ✅ Completed |
| **Phase 2.5: UI Prototypes** | Course cards, Deliverable lists (with GitHub/Video chips), Navigation | ✅ Completed |
| **Phase 2.8: Schedule & Calendar Engine** | Weekly timetable, day selector, user-controlled calendar sync toggle | ✅ Completed |
| **Phase 3: Identity & Cloud Backend** | Firebase Auth (Google Sign-In), Cloud Firestore configuration | ⏳ Next Up |
| **Phase 4: Dynamic CRUD & Forms** | Interactive modals for adding courses, deliverables, and custom schedule slots | ⏳ Upcoming |
| **Phase 5: AI Academic Assistant** | LLM API integration with prompt engineering for schedule realignment | ⏳ Upcoming |

---

## 🧪 Testing & Verification
The codebase is verified using automated unit and widget tests:
- **`test/models_test.dart`**: Validates entity immutability, JSON/Map serialization (`toMap`), deserialization (`fromMap`), and computed properties.
- **`test/widget_test.dart`**: Validates UI tree composition and navigation rendering.

To execute tests:
```bash
flutter test
```

---

## 🚀 How to Run the Application
```bash
# Clone the repository
git clone https://github.com/benhrnndz/app-storage.git
cd app-storage

# Fetch dependencies
flutter pub get

# Run on Google Chrome (Instant live reload)
flutter run -d chrome

# Or run on macOS Desktop
flutter run -d macos
```
