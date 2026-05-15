# SkyTrack System Architecture

## System Overview

SkyTrack is a distributed weather tracking application with a Flutter mobile frontend and Laravel REST API backend.

```
┌─────────────────────────────────────────────────────────────────┐
│                     USER DEVICES                                │
├─────────────────────────────────────────────────────────────────┤
│  iOS | Android | Web | macOS | Windows | Linux                  │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     │ HTTP/HTTPS
                     │
┌────────────────────▼────────────────────────────────────────────┐
│              FLUTTER MOBILE APPLICATION                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ UI Layer (Screens & Widgets)                             │  │
│  │ ├─ LoginScreen (Auth)                                    │  │
│  │ ├─ WeatherHome (Main Dashboard)                          │  │
│  │ ├─ SavedCities (City Management)                         │  │
│  │ └─ SearchAutocomplete (City Search)                      │  │
│  └──────────────────────────────────────────────────────────┘  │
│                         ▲                                       │
│                         │                                       │
│  ┌──────────────────────▼──────────────────────────────────┐  │
│  │ Business Logic & State Management                       │  │
│  │ ├─ WeatherData Model                                    │  │
│  │ ├─ SavedCity Model                                      │  │
│  │ ├─ Theme Management (Light/Dark)                        │  │
│  │ └─ Temperature Conversion                               │  │
│  └──────────────────────────────────────────────────────────┘  │
│                         ▲                                       │
│                         │                                       │
│  ┌──────────────────────▼──────────────────────────────────┐  │
│  │ Data & Storage Layer                                    │  │
│  │ ├─ CityStorage (JSON serialization)                     │  │
│  │ ├─ SharedPreferences (User session, theme)             │  │
│  │ └─ HTTP Client (REST API calls)                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     │ REST API Calls
                     │ (JSON over HTTP)
                     │
┌────────────────────▼────────────────────────────────────────────┐
│           LARAVEL REST API BACKEND                              │
│  (http://127.0.0.1:8000/api)                                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Route Layer                                              │  │
│  │ ├─ POST   /register → AuthController@register           │  │
│  │ ├─ POST   /login → AuthController@login                 │  │
│  │ ├─ GET    /weather/{city} → WeatherController@show      │  │
│  │ ├─ GET    /cities/search → CityController@search        │  │
│  │ └─ GET    /profile → ProfileController@show             │  │
│  └──────────────────────────────────────────────────────────┘  │
│                         ▲                                       │
│                         │                                       │
│  ┌──────────────────────▼──────────────────────────────────┐  │
│  │ Controller Layer                                         │  │
│  │ ├─ AuthController (Login/Register logic)               │  │
│  │ ├─ WeatherController (Weather data retrieval)          │  │
│  │ ├─ CityController (City search logic)                  │  │
│  │ └─ ProfileController (User profile management)          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                         ▲                                       │
│                         │                                       │
│  ┌──────────────────────▼──────────────────────────────────┐  │
│  │ Business Logic & Middleware                             │  │
│  │ ├─ Authentication (JWT/Token verification)             │  │
│  │ ├─ Validation (Input validation & sanitization)        │  │
│  │ ├─ Error Handling (Exception & error responses)        │  │
│  │ └─ Rate Limiting (API request throttling)              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                         ▲                                       │
│                         │                                       │
│  ┌──────────────────────▼──────────────────────────────────┐  │
│  │ Data & External Services                                │  │
│  │ ├─ MySQL Database (Users, Cities, Weather cache)       │  │
│  │ ├─ External Weather API (WeatherAPI.com / similar)    │  │
│  │ └─ Cache (Redis/Memcached for performance)            │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
                     │
                     │ Database queries
                     │
┌────────────────────▼────────────────────────────────────────────┐
│                   DATABASE                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Tables:                                                  │  │
│  │ ├─ users (id, name, email, password, created_at)       │  │
│  │ ├─ saved_cities (id, user_id, city, condition, temp...)│  │
│  │ ├─ cities (id, name, country, latitude, longitude)     │  │
│  │ └─ weather_cache (id, city, data, updated_at)         │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

---

## Component Responsibilities

### Frontend (Flutter)

| Component | Responsibility |
|-----------|-----------------|
| **LoginScreen** | Handle user registration & authentication |
| **WeatherHome** | Display current weather & manage saved cities |
| **SearchAutocomplete** | Provide city search with typeahead |
| **CityStorage** | Persist saved cities locally |
| **AppTheme** | Manage light/dark theme preferences |

### Backend (Laravel)

| Component | Responsibility |
|-----------|-----------------|
| **AuthController** | User registration, login, token generation |
| **WeatherController** | Fetch weather data for cities |
| **CityController** | Provide city search suggestions |
| **ProfileController** | Retrieve user profile & saved cities |
| **Authentication Middleware** | Verify JWT tokens, protect routes |
| **Database Models** | User, City, SavedCity, WeatherCache |

---

## Data Flow

### Authentication Flow
```
User Input (Email/Password)
    ↓
[LoginScreen] validates input
    ↓
HTTP POST /api/login or /api/register
    ↓
[AuthController] validates credentials
    ↓
[User Model] check/create user in database
    ↓
Generate JWT token
    ↓
Return token to Flutter
    ↓
Store token in SharedPreferences
    ↓
Navigate to WeatherHome
```

### Weather Fetch Flow
```
User searches city (e.g., "Manila")
    ↓
[SearchAutocomplete] queries /api/cities/search
    ↓
[CityController] searches cities table
    ↓
Return matching cities
    ↓
User selects city
    ↓
[WeatherHome] calls /api/weather/{city}
    ↓
[WeatherController] queries database or external API
    ↓
Return weather data (temp, condition, humidity, etc.)
    ↓
Display in UI with temperature conversion
    ↓
Save to local storage if selected as favorite
```

### User Profile Flow
```
User taps profile icon
    ↓
[ProfileScreen] calls GET /api/profile
    ↓
[Auth Middleware] verifies JWT token
    ↓
[ProfileController] retrieves user data
    ↓
Query users table + saved_cities relation
    ↓
Return user profile with saved cities
    ↓
Display in UI
```

---

## Technology Stack

### Frontend
- **Framework:** Flutter 3.11.5
- **Language:** Dart
- **HTTP:** http package v1.6.0
- **Storage:** shared_preferences v2.3.2
- **UI:** Material Design 3

### Backend
- **Framework:** Laravel (PHP)
- **Database:** MySQL
- **Authentication:** JWT (JSON Web Tokens)
- **API:** RESTful JSON
- **External Services:** Weather API integration

### Data Format
- **Serialization:** JSON
- **Protocol:** HTTP/HTTPS

---

## Security Architecture

### Frontend Security
- ✅ Credentials stored securely in SharedPreferences
- ✅ Token-based authentication (JWT)
- ✅ HTTPS support for API calls
- ✅ Input validation on forms
- ✅ Session management with logout capability

### Backend Security
- ✅ JWT token verification on protected routes
- ✅ Password hashing (bcrypt)
- ✅ SQL injection prevention (Laravel ORM)
- ✅ CORS configuration for mobile clients
- ✅ Rate limiting on authentication endpoints
- ✅ Email validation & uniqueness checks

---

## Scalability Considerations

### Current State
- Single Laravel instance
- Single MySQL database
- Direct HTTP calls from mobile app

### Future Enhancements
- Database replication for high availability
- Redis caching layer for weather data
- CDN for static assets
- Microservices for weather data aggregation
- Mobile app push notifications (FCM)
- Webhook support for real-time updates

---

## Deployment Architecture

### Development
```
Frontend: Flutter dev server (localhost)
Backend: Laravel artisan serve (localhost:8000)
Database: Local MySQL instance
```

### Production
```
Frontend: App Store / Play Store / Web deployment
Backend: Cloud server (AWS/GCP/Azure)
Database: Managed database service
Cache: Redis cluster
Load Balancer: NGINX/HAProxy
```

---

## API Integration Points

| Endpoint | Method | Frontend Call | Purpose |
|----------|--------|---------------|---------|
| `/register` | POST | LoginScreen.\_login() | User registration |
| `/login` | POST | LoginScreen.\_login() | User authentication |
| `/weather/{city}` | GET | WeatherHome.\_fetchWeather() | Weather data retrieval |
| `/cities/search` | GET | SearchAutocomplete.onSearchChanged() | City autocomplete |
| `/profile` | GET | ProfileScreen.onInit() | User profile retrieval |

---

## Database Schema Overview

### Users Table
```sql
CREATE TABLE users (
  id INT PRIMARY KEY,
  name VARCHAR(255),
  email VARCHAR(255) UNIQUE,
  password VARCHAR(255),
  created_at TIMESTAMP
);
```

### Saved Cities Table
```sql
CREATE TABLE saved_cities (
  id INT PRIMARY KEY,
  user_id INT FOREIGN KEY,
  city VARCHAR(255),
  condition VARCHAR(100),
  temp INT,
  humidity INT,
  is_pinned BOOLEAN,
  created_at TIMESTAMP
);
```

### Cities Table
```sql
CREATE TABLE cities (
  id INT PRIMARY KEY,
  name VARCHAR(255),
  country VARCHAR(100),
  latitude DECIMAL,
  longitude DECIMAL
);
```

---

## Monitoring & Logging

### Frontend Logging
- API request/response logs
- Error stack traces
- User action tracking

### Backend Logging
- HTTP request logs
- Database query logs
- Authentication attempts
- API performance metrics

---

**Last Updated:** May 15, 2026  
**Version:** 1.0  
**Architecture Owner:** SkyTrack Development Team
