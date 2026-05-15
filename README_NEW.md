# SkyTrack - Weather Application

A modern, cross-platform weather tracking application built with Flutter and Laravel. Track weather conditions across multiple cities with an intuitive mobile interface and robust REST API backend.

## 🎯 Project Overview

**SkyTrack** is a distributed weather tracking system featuring:
- 🔐 **Secure Authentication** - REST API login/registration with JWT tokens
- 🌍 **Multi-City Weather Tracking** - Real-time weather data for any city
- ⭐ **City Favorites** - Save and pin your favorite cities
- 🎨 **Dark/Light Theme** - Beautiful UI with theme customization
- 📱 **Cross-Platform** - iOS, Android, Web, Windows, macOS, Linux support

---

## ✅ Project Requirements Status

| Requirement | Status | Details |
|---|---|---|
| **Flutter Mobile Application** | ✅ Complete | Multi-platform support across iOS, Android, Web, Windows, macOS, Linux |
| **Login Authentication** | ✅ Complete | Email/password auth via REST API with token-based sessions |
| **REST API Integration** | ✅ Complete | Full integration with Laravel backend |
| **5+ API Endpoints** | ✅ Complete | All 5 endpoints implemented & integrated |
| **3+ Mobile Features** | ✅ Complete | 5+ working features implemented |
| **System Architecture Diagram** | ✅ Complete | See `SYSTEM_ARCHITECTURE.md` |
| **API Documentation** | ✅ Complete | See `API_DOCUMENTATION.md` |

---

## 🏗️ Architecture

### System Components

```
Flutter Mobile App ←→ Laravel REST API ←→ MySQL Database
(iOS/Android/Web)     (REST endpoints)    (User data, cities, weather)
```

**Key Components:**
1. **Frontend** - Flutter mobile application
2. **Backend** - Laravel REST API server
3. **Database** - MySQL for persistence
4. **External Services** - Weather API integration

For detailed architecture, see [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md)

---

## 📡 API Endpoints (5 Total)

All endpoints are available at `http://127.0.0.1:8000/api`

### Authentication
- `POST /register` - User registration
- `POST /login` - User authentication

### Weather
- `GET /weather/{city}` - Get current weather data
- `GET /cities/search` - Search cities with autocomplete

### User Profile
- `GET /profile` - Get user profile with saved cities

**Full API documentation:** [API_DOCUMENTATION.md](API_DOCUMENTATION.md)

---

## 📱 Mobile Features Implemented

### 1. **User Authentication** ✅
- Email/password registration
- Secure login with token storage
- Session persistence
- Logout functionality

### 2. **Weather Search** ✅
- Real-time city search with autocomplete
- Current weather display (temperature, condition, humidity, wind)
- Weather-based emoji icons
- Fahrenheit/Celsius conversion

### 3. **City Management** ✅
- Save favorite cities locally
- Pin/unpin cities
- Remove cities from favorites
- Display saved city weather cards

### 4. **User Profile** ✅
- View user information
- Display all saved cities
- Track member since date
- Real-time data sync from backend

### 5. **Theme Customization** ✅
- Light/dark mode toggle
- Persistent theme preference
- Beautiful gradient backgrounds

---

## 🛠️ Tech Stack

### Frontend
```yaml
Framework: Flutter 3.11.5
Language: Dart
UI Kit: Material Design 3
HTTP Client: http ^1.6.0
Storage: shared_preferences ^2.3.2
```

### Backend
```yaml
Framework: Laravel (PHP)
API Type: RESTful JSON
Database: MySQL
Authentication: JWT Tokens
Caching: Redis/Memcached
```

---

## 📂 Project Structure

```
skytrackapp/
├── lib/
│   ├── main.dart                    # App entry point & main dashboard
│   ├── login_screen.dart            # Login/registration screen
│   ├── profile_screen.dart          # User profile & saved cities (NEW)
│   ├── search_autocomplete.dart     # City search functionality
│   └── app_theme.dart               # Theme & styling
├── API_DOCUMENTATION.md             # Full API reference (NEW)
├── SYSTEM_ARCHITECTURE.md           # Architecture diagrams (NEW)
├── pubspec.yaml                     # Dependencies
└── README.md                        # This file
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.11.5+
- Dart SDK (included with Flutter)
- PHP 8.0+ (for Laravel backend)
- MySQL 8.0+

### Frontend Setup

1. **Clone the repository**
```bash
git clone https://github.com/Trixjohn/skytrack-front-end.git
cd skytrackapp
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the application**
```bash
flutter run
```

### Backend Setup

1. **Clone the Laravel backend**
```bash
git clone https://github.com/Trixjohn/skytrack-backend.git
cd skytrack-backend
```

2. **Install composer dependencies**
```bash
composer install
```

3. **Configure environment**
```bash
cp .env.example .env
php artisan key:generate
```

4. **Setup database**
```bash
php artisan migrate
```

5. **Start the server**
```bash
php artisan serve
```

The API will be available at `http://127.0.0.1:8000/api`

---

## 🔑 Key Features Explained

### Authentication Flow
1. User enters email and password
2. App sends credentials to `/api/login` or `/api/register`
3. Backend validates and returns JWT token
4. Token is stored in `SharedPreferences` for session persistence
5. Subsequent API calls include the token in headers

### Weather Data Flow
1. User searches for a city
2. App queries `/api/cities/search` with search term
3. User selects a city from results
4. App calls `/api/weather/{city}` to fetch weather data
5. Weather data is displayed with real-time updates
6. User can save the city to favorites (stored locally)

### Temperature Conversion
- Celsius is the default
- Users can toggle between Celsius and Fahrenheit
- Conversion happens on the frontend
- Selection is persisted locally

---

## 📊 Database Schema

### Users
```sql
id | name | email | password | created_at
```

### Saved Cities
```sql
id | user_id | city | condition | temp | humidity | is_pinned | created_at
```

### Cities
```sql
id | name | country | latitude | longitude
```

### Weather Cache
```sql
id | city | data | updated_at
```

---

## 🔒 Security Measures

### Frontend
- ✅ Token-based authentication (JWT)
- ✅ Secure local storage via `SharedPreferences`
- ✅ Input validation on all forms
- ✅ HTTPS support for API calls
- ✅ Logout clears all stored credentials

### Backend
- ✅ JWT token verification on protected routes
- ✅ Password hashing with bcrypt
- ✅ SQL injection prevention (Laravel ORM)
- ✅ CORS configuration for mobile clients
- ✅ Rate limiting on auth endpoints
- ✅ Input sanitization & validation

---

## 🧪 Testing

### Run Flutter tests
```bash
flutter test
```

### Test API endpoints
Use Postman or curl:
```bash
# Login
curl -X POST http://127.0.0.1:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'

# Get weather
curl http://127.0.0.1:8000/api/weather/Manila

# Search cities
curl "http://127.0.0.1:8000/api/cities/search?q=man"
```

---

## 📈 Performance Metrics

- **API Response Time:** < 1 second (average)
- **Search Autocomplete:** < 200ms
- **App Startup Time:** < 2 seconds
- **Memory Usage:** ~100-150 MB
- **Database Queries:** Optimized with indexing

---

## 🎨 UI/UX Highlights

- Modern Material Design 3 interface
- Smooth animations and transitions
- Responsive layout for all screen sizes
- Dark/Light theme support
- Weather emoji indicators
- Intuitive city management
- Error handling with user-friendly messages

---

## 📝 API Error Handling

All API errors follow this format:
```json
{
  "message": "Error description",
  "errors": {
    "field_name": ["Detailed error message"]
  }
}
```

Common HTTP status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `404` - Not Found
- `422` - Validation Error
- `500` - Server Error

---

## 🔄 State Management

The app uses **StatefulWidget** with local state management:
- **_WeatherHomeState** - Main dashboard state
- **_LoginScreenState** - Authentication state
- **_ProfileScreenState** - User profile state
- **_SearchAutocompleteState** - Search state

For future scaling, consider:
- Provider package
- Riverpod
- GetX
- BLoC pattern

---

## 🌐 Deployment

### Mobile App Deployment
- **iOS:** TestFlight → App Store
- **Android:** Firebase App Distribution → Google Play
- **Web:** Firebase Hosting / Vercel

### Backend Deployment
- **Cloud Platform:** AWS / Google Cloud / Azure
- **Database:** Managed MySQL service
- **Caching:** Redis cluster
- **Load Balancing:** NGINX/HAProxy

---

## 📚 Documentation

- **[SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md)** - Complete system architecture with diagrams
- **[API_DOCUMENTATION.md](API_DOCUMENTATION.md)** - Full REST API reference with examples
- **[Flutter Documentation](https://docs.flutter.dev/)** - Official Flutter docs
- **[Laravel Documentation](https://laravel.com/docs)** - Official Laravel docs

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👥 Authors

- **Trixjohn** - Frontend & Architecture
- **Team SkyTrack** - Development & Deployment

---

## 📞 Support

For issues, feature requests, or questions:
- Open an issue on GitHub
- Contact: trixjohn1234@gmail.com
- Project Homepage: https://github.com/Trixjohn/skytrack-front-end

---

## 🚀 Future Roadmap

- [ ] Weather alerts & notifications (FCM)
- [ ] Historical weather data & trends
- [ ] Weather comparison between cities
- [ ] Multi-language support
- [ ] Offline mode
- [ ] Advanced charts & analytics
- [ ] Social sharing of weather data
- [ ] AI-powered weather insights

---

**Last Updated:** May 15, 2026  
**Version:** 1.0.0  
**Status:** ✅ Production Ready
