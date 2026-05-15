# SkyTrack Weather App — Flutter API Documentation

> **Version:** 1.0.0 | **Base URL:** `http://localhost:8000/api` | **Format:** JSON

---

## Table of Contents

1. [Overview](#overview)
2. [Setup — Flutter `http` Package](#setup)
3. [Authentication Notes](#authentication-notes)
4. [Endpoints](#endpoints)
   - [1. Register](#1-post-register)
   - [2. Login](#2-post-login)
   - [3. Forgot Password](#3-post-forgot-password)
   - [4. Get Weather by City](#4-get-weathercity)
   - [5. Get All Weather Logs](#5-get-weather)
   - [6. Add Weather Log](#6-post-weather)
   - [7. Update Weather Log](#7-put-weatherid)
   - [8. Delete Weather Log](#8-delete-weatherid)
5. [API Summary Table](#api-summary-table)
6. [Error Handling](#error-handling)

---

## Overview

The **SkyTrack API** is a RESTful JSON API built with Laravel. It provides weather data retrieval and user management features for the SkyTrack Flutter mobile application.

- All requests and responses use `Content-Type: application/json`.
- There are exactly **8 endpoints** in this API.
- Authentication is currently **sessionless and simple** — it does **not** use JWT tokens, Bearer tokens, or Laravel Sanctum. No `Authorization` headers are needed.
- The base URL for all endpoints is: `http://localhost:8000/api`

---

## Setup

### Adding the `http` Package

In your Flutter project's `pubspec.yaml`, add:

```yaml
dependencies:
  http: ^1.2.1
```

Then run:

```bash
flutter pub get
```

### Base Configuration

Create a constants file `lib/constants/api_constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8000/api';
}
```

Import the `http` package wherever you make API calls:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:skytrack/constants/api_constants.dart';
```

---

## Authentication Notes

> **Important for Developers**
>
> SkyTrack's current backend uses **simple, sessionless authentication**.
>
> - There is **no JWT** (JSON Web Token) issued on login.
> - There is **no Bearer token** to store or attach to requests.
> - There is **no Laravel Sanctum** or Passport integration.
> - There is **no `/profile` endpoint**.
> - There is **no `/cities/search` autocomplete endpoint**.
>
> After a successful login, the API returns a `message` confirming the login. The frontend is responsible for managing its own session state (e.g., storing the user's name locally using `SharedPreferences` or similar).

---

## Endpoints

---

### 1. POST `/register`

Registers a new user account.

**Full URL:** `POST http://localhost:8000/api/register`

#### Request Headers

| Header         | Value              |
|----------------|--------------------|
| `Content-Type` | `application/json` |
| `Accept`       | `application/json` |

#### Request Body

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "secret123",
  "password_confirmation": "secret123"
}
```

| Field                   | Type   | Required | Description                          |
|-------------------------|--------|----------|--------------------------------------|
| `name`                  | string | ✅       | Full name of the user                |
| `email`                 | string | ✅       | Valid email address                  |
| `password`              | string | ✅       | Minimum 6 characters                 |
| `password_confirmation` | string | ✅       | Must match `password`                |

#### Success Response — `201 Created`

```json
{
  "message": "User registered successfully."
}
```

#### Error Response — `422 Unprocessable Entity`

```json
{
  "message": "The email has already been taken.",
  "errors": {
    "email": ["The email has already been taken."]
  }
}
```

#### Flutter Code Example

```dart
Future<void> register({
  required String name,
  required String email,
  required String password,
}) async {
  final url = Uri.parse('${ApiConstants.baseUrl}/register');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 201) {
    print('Registered: \${data['message']}');
  } else {
    print('Registration failed: \${data['message']}');
  }
}
```

---

### 2. POST `/login`

Authenticates an existing user.

**Full URL:** `POST http://localhost:8000/api/login`

#### Request Headers

| Header         | Value              |
|----------------|--------------------|
| `Content-Type` | `application/json` |
| `Accept`       | `application/json` |

#### Request Body

```json
{
  "email": "john@example.com",
  "password": "secret123"
}
```

| Field      | Type   | Required | Description              |
|------------|--------|----------|--------------------------|
| `email`    | string | ✅       | Registered email address |
| `password` | string | ✅       | Account password         |

#### Success Response — `200 OK`

```json
{
  "message": "Login successful.",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

#### Error Response — `401 Unauthorized`

```json
{
  "message": "Invalid credentials."
}
```

#### Flutter Code Example

```dart
Future<Map<String, dynamic>?> login({
  required String email,
  required String password,
}) async {
  final url = Uri.parse('${ApiConstants.baseUrl}/login');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    // No token is returned — store user info locally as needed
    print('Welcome \${data['user']['name']}');
    return data['user'] as Map<String, dynamic>;
  } else {
    print('Login failed: \${data['message']}');
    return null;
  }
}
```

---

### 3. POST `/forgot-password`

Sends a password reset request for the given email.

**Full URL:** `POST http://localhost:8000/api/forgot-password`

#### Request Headers

| Header         | Value              |
|----------------|--------------------|
| `Content-Type` | `application/json` |
| `Accept`       | `application/json` |

#### Request Body

```json
{
  "email": "john@example.com"
}
```

| Field   | Type   | Required | Description                   |
|---------|--------|----------|-------------------------------|
| `email` | string | ✅       | Email address of the account  |

#### Success Response — `200 OK`

```json
{
  "message": "Password reset link sent."
}
```

#### Error Response — `404 Not Found`

```json
{
  "message": "Email not found."
}
```

#### Flutter Code Example

```dart
Future<void> forgotPassword({required String email}) async {
  final url = Uri.parse('${ApiConstants.baseUrl}/forgot-password');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode({'email': email}),
  );

  final data = jsonDecode(response.body);
  print(data['message']);
}
```

---

### 4. GET `/weather/{city}`

Fetches real-time weather data for a specific city by name.

**Full URL:** `GET http://localhost:8000/api/weather/{city}`

#### URL Parameters

| Parameter | Type   | Required | Description                     |
|-----------|--------|----------|---------------------------------|
| `city`    | string | ✅       | Name of the city (URL-encoded)  |

#### Request Headers

| Header   | Value              |
|----------|--------------------|
| `Accept` | `application/json` |

#### Success Response — `200 OK`

```json
{
  "city": "Manila",
  "temperature": 31.5,
  "humidity": 78,
  "description": "partly cloudy",
  "wind_speed": 14.2,
  "fetched_at": "2025-05-15T10:30:00Z"
}
```

| Field         | Type    | Description                              |
|---------------|---------|------------------------------------------|
| `city`        | string  | City name                                |
| `temperature` | float   | Temperature in degrees Celsius           |
| `humidity`    | integer | Humidity percentage                      |
| `description` | string  | Short weather description                |
| `wind_speed`  | float   | Wind speed in km/h                       |
| `fetched_at`  | string  | ISO 8601 timestamp of the data retrieval |

#### Error Response — `404 Not Found`

```json
{
  "message": "City not found."
}
```

#### Flutter Code Example

```dart
Future<Map<String, dynamic>?> fetchWeatherByCity(String city) async {
  final encodedCity = Uri.encodeComponent(city);
  final url = Uri.parse('${ApiConstants.baseUrl}/weather/$encodedCity');

  final response = await http.get(
    url,
    headers: {'Accept': 'application/json'},
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data as Map<String, dynamic>;
  } else {
    print('Error: \${data['message']}');
    return null;
  }
}
```

---

### 5. GET `/weather`

Retrieves a list of all stored weather log entries.

**Full URL:** `GET http://localhost:8000/api/weather`

#### Request Headers

| Header   | Value              |
|----------|--------------------|
| `Accept` | `application/json` |

#### Query Parameters

_None._

#### Success Response — `200 OK`

```json
[
  {
    "id": 1,
    "city": "Manila",
    "temperature": 31.5,
    "humidity": 78,
    "description": "partly cloudy",
    "wind_speed": 14.2,
    "created_at": "2025-05-15T10:30:00Z",
    "updated_at": "2025-05-15T10:30:00Z"
  },
  {
    "id": 2,
    "city": "Cebu",
    "temperature": 33.0,
    "humidity": 70,
    "description": "clear sky",
    "wind_speed": 10.1,
    "created_at": "2025-05-15T11:00:00Z",
    "updated_at": "2025-05-15T11:00:00Z"
  }
]
```

#### Flutter Code Example

```dart
Future<List<dynamic>> getWeatherLogs() async {
  final url = Uri.parse('${ApiConstants.baseUrl}/weather');

  final response = await http.get(
    url,
    headers: {'Accept': 'application/json'},
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as List<dynamic>;
  } else {
    print('Failed to load weather logs.');
    return [];
  }
}
```

---

### 6. POST `/weather`

Creates a new weather log entry in the database.

**Full URL:** `POST http://localhost:8000/api/weather`

#### Request Headers

| Header         | Value              |
|----------------|--------------------|
| `Content-Type` | `application/json` |
| `Accept`       | `application/json` |

#### Request Body

```json
{
  "city": "Davao",
  "temperature": 29.8,
  "humidity": 80,
  "description": "light rain",
  "wind_speed": 8.5
}
```

| Field         | Type    | Required | Description                     |
|---------------|---------|----------|---------------------------------|
| `city`        | string  | ✅       | Name of the city                |
| `temperature` | float   | ✅       | Temperature in degrees Celsius  |
| `humidity`    | integer | ✅       | Humidity percentage             |
| `description` | string  | ✅       | Short weather description       |
| `wind_speed`  | float   | ✅       | Wind speed in km/h              |

#### Success Response — `201 Created`

```json
{
  "message": "Weather log created successfully.",
  "data": {
    "id": 3,
    "city": "Davao",
    "temperature": 29.8,
    "humidity": 80,
    "description": "light rain",
    "wind_speed": 8.5,
    "created_at": "2025-05-15T12:00:00Z",
    "updated_at": "2025-05-15T12:00:00Z"
  }
}
```

#### Error Response — `422 Unprocessable Entity`

```json
{
  "message": "The city field is required.",
  "errors": {
    "city": ["The city field is required."]
  }
}
```

#### Flutter Code Example

```dart
Future<void> addWeatherLog({
  required String city,
  required double temperature,
  required int humidity,
  required String description,
  required double windSpeed,
}) async {
  final url = Uri.parse('${ApiConstants.baseUrl}/weather');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode({
      'city': city,
      'temperature': temperature,
      'humidity': humidity,
      'description': description,
      'wind_speed': windSpeed,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 201) {
    print('Log created: \${data['message']}');
  } else {
    print('Failed: \${data['message']}');
  }
}
```

---

### 7. PUT `/weather/{id}`

Updates an existing weather log entry by its ID.

**Full URL:** `PUT http://localhost:8000/api/weather/{id}`

#### URL Parameters

| Parameter | Type    | Required | Description                   |
|-----------|---------|----------|-------------------------------|
| `id`      | integer | ✅       | ID of the weather log to edit |

#### Request Headers

| Header         | Value              |
|----------------|--------------------|
| `Content-Type` | `application/json` |
| `Accept`       | `application/json` |

#### Request Body

Send only the fields you want to update. All fields are optional on update.

```json
{
  "city": "Davao",
  "temperature": 30.5,
  "humidity": 75,
  "description": "overcast clouds",
  "wind_speed": 9.0
}
```

#### Success Response — `200 OK`

```json
{
  "message": "Weather log updated successfully.",
  "data": {
    "id": 3,
    "city": "Davao",
    "temperature": 30.5,
    "humidity": 75,
    "description": "overcast clouds",
    "wind_speed": 9.0,
    "created_at": "2025-05-15T12:00:00Z",
    "updated_at": "2025-05-15T12:30:00Z"
  }
}
```

#### Error Response — `404 Not Found`

```json
{
  "message": "Weather log not found."
}
```

#### Flutter Code Example

```dart
Future<void> updateWeatherLog(int id, Map<String, dynamic> updatedFields) async {
  final url = Uri.parse('${ApiConstants.baseUrl}/weather/$id');

  final response = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode(updatedFields),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    print('Updated: \${data['message']}');
  } else {
    print('Update failed: \${data['message']}');
  }
}
```

---

### 8. DELETE `/weather/{id}`

Deletes a weather log entry by its ID.

**Full URL:** `DELETE http://localhost:8000/api/weather/{id}`

#### URL Parameters

| Parameter | Type    | Required | Description                     |
|-----------|---------|----------|---------------------------------|
| `id`      | integer | ✅       | ID of the weather log to delete |

#### Request Headers

| Header   | Value              |
|----------|--------------------|
| `Accept` | `application/json` |

#### Success Response — `200 OK`

```json
{
  "message": "Weather log deleted successfully."
}
```

#### Error Response — `404 Not Found`

```json
{
  "message": "Weather log not found."
}
```

#### Flutter Code Example

```dart
Future<void> deleteWeatherLog(int id) async {
  final url = Uri.parse('${ApiConstants.baseUrl}/weather/$id');

  final response = await http.delete(
    url,
    headers: {'Accept': 'application/json'},
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    print('Deleted: \${data['message']}');
  } else {
    print('Delete failed: \${data['message']}');
  }
}
```

---

## API Summary Table

| # | Method   | Endpoint           | Description                        | Auth Required | Success Code |
|---|----------|--------------------|------------------------------------|---------------|--------------|
| 1 | `POST`   | `/register`        | Register a new user                | ❌ No         | `201`        |
| 2 | `POST`   | `/login`           | Authenticate an existing user      | ❌ No         | `200`        |
| 3 | `POST`   | `/forgot-password` | Send a password reset request      | ❌ No         | `200`        |
| 4 | `GET`    | `/weather/{city}`  | Fetch live weather for a city      | ❌ No         | `200`        |
| 5 | `GET`    | `/weather`         | Get all weather log entries        | ❌ No         | `200`        |
| 6 | `POST`   | `/weather`         | Create a new weather log entry     | ❌ No         | `201`        |
| 7 | `PUT`    | `/weather/{id}`    | Update an existing weather log     | ❌ No         | `200`        |
| 8 | `DELETE` | `/weather/{id}`    | Delete a weather log entry         | ❌ No         | `200`        |

> **Note:** This API currently has no authentication guard on routes. No Bearer token or session cookie is required for any request. This may change in a future version.

---

## Error Handling

### Common HTTP Status Codes

| Status Code | Meaning               | When It Occurs                                       |
|-------------|-----------------------|------------------------------------------------------|
| `200`       | OK                    | Request succeeded                                    |
| `201`       | Created               | Resource successfully created                        |
| `401`       | Unauthorized          | Invalid credentials on login                         |
| `404`       | Not Found             | City or record ID does not exist                     |
| `422`       | Unprocessable Entity  | Validation error (missing or invalid fields)         |
| `500`       | Internal Server Error | Unexpected backend error                             |

### Flutter Global Error Handler (Recommended Pattern)

```dart
void handleApiError(http.Response response) {
  final data = jsonDecode(response.body);
  final message = data['message'] ?? 'An unexpected error occurred.';

  switch (response.statusCode) {
    case 401:
      print('Unauthorized: $message');
      break;
    case 404:
      print('Not Found: $message');
      break;
    case 422:
      print('Validation Error: $message');
      // Optionally parse data['errors'] for field-level messages
      break;
    case 500:
      print('Server Error: $message');
      break;
    default:
      print('Error \${response.statusCode}: $message');
  }
}
```

---

*SkyTrack Weather App — Flutter API Documentation v1.0.0*
*Backend: Laravel | Frontend: Flutter | Generated: 2026-05-15*
