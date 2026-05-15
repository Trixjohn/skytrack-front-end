# SkyTrack API Documentation

## Overview
SkyTrack is a weather tracking application that integrates with a Laravel backend via REST API. The application provides real-time weather data, city management, and user authentication.

**Base URL:** `http://127.0.0.1:8000/api`

---

## Authentication Endpoints

### 1. **User Registration**
**Endpoint:** `POST /register`

Register a new user account with email and password.

**Request:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Error Response (422 Unprocessable Entity):**
```json
{
  "message": "Email already exists"
}
```

---

### 2. **User Login**
**Endpoint:** `POST /login`

Authenticate user and retrieve session token.

**Request:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Error Response (401 Unauthorized):**
```json
{
  "message": "Invalid email or password"
}
```

---

## Weather Endpoints

### 3. **Get Weather by City**
**Endpoint:** `GET /weather/{city}`

Fetch current weather data for a specific city.

**Parameters:**
- `city` (string, path) - City name (e.g., "Manila", "Bangkok")

**Request Example:**
```
GET /weather/Manila
```

**Response (200 OK):**
```json
{
  "city": "Manila",
  "country": "Philippines",
  "condition": "Partly Cloudy",
  "temp": 29,
  "feelsLike": 32,
  "humidity": 75,
  "windKph": 12,
  "uvIndex": 7,
  "visibility": 10
}
```

**Error Response (404 Not Found):**
```json
{
  "message": "City not found"
}
```

---

### 4. **Search Cities Autocomplete**
**Endpoint:** `GET /cities/search`

Search for cities with autocomplete suggestions.

**Parameters:**
- `q` (string, query) - Search query (minimum 2 characters)

**Request Example:**
```
GET /cities/search?q=manila
```

**Response (200 OK):**
```json
{
  "cities": [
    {
      "id": 1,
      "name": "Manila",
      "country": "Philippines",
      "latitude": 14.5995,
      "longitude": 120.9842
    },
    {
      "id": 2,
      "name": "Manila Bay",
      "country": "Philippines",
      "latitude": 14.5890,
      "longitude": 120.8754
    }
  ]
}
```

**Error Response (400 Bad Request):**
```json
{
  "message": "Search query must be at least 2 characters"
}
```

---

## User Profile Endpoints

### 5. **Get User Profile**
**Endpoint:** `GET /profile`

Retrieve authenticated user's profile information.

**Headers:**
```
Authorization: Bearer {token}
```

**Request Example:**
```
GET /profile
```

**Response (200 OK):**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "savedCities": [
    {
      "id": 101,
      "city": "Manila",
      "condition": "Partly Cloudy",
      "temp": 29,
      "isPinned": true
    }
  ],
  "createdAt": "2026-05-15T10:30:00Z",
  "updatedAt": "2026-05-15T10:35:00Z"
}
```

**Error Response (401 Unauthorized):**
```json
{
  "message": "Unauthenticated"
}
```

---

## HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK - Request successful |
| 201 | Created - Resource created successfully |
| 400 | Bad Request - Invalid parameters |
| 401 | Unauthorized - Authentication required |
| 404 | Not Found - Resource not found |
| 422 | Unprocessable Entity - Validation error |
| 500 | Internal Server Error |

---

## Error Handling

All error responses follow this format:
```json
{
  "message": "Error description",
  "errors": {
    "field_name": ["Error message"]
  }
}
```

---

## Rate Limiting

- **Weather endpoints:** 100 requests per hour per IP
- **Search endpoint:** 50 requests per minute per IP
- **Auth endpoints:** 5 attempts per 15 minutes per IP

---

## Implementation Notes

### Frontend Integration (Flutter)
The SkyTrack mobile app integrates with these endpoints using:
- **HTTP Client:** `http` package v1.6.0
- **Local Storage:** `shared_preferences` v2.3.2
- **Session Management:** Token stored in SharedPreferences

### Example Frontend Call:
```dart
final response = await http.post(
  Uri.parse('http://127.0.0.1:8000/api/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'email': 'user@example.com',
    'password': 'password123'
  }),
);
```

---

## Support & Testing

For API testing, use:
- **Postman:** Import base URL and endpoints above
- **cURL:** Available in terminal
- **Flutter App:** Built-in integration testing available

Last updated: **May 15, 2026**
