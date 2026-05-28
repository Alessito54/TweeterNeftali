# Manual de Prueba - Login y Tweets con Bearer Token

## 📋 Resumen de Cambios

He implementado un sistema completo de autenticación para tu aplicación Flutter Tweeter que consume APIs RESTful. El sistema guarda el token en almacenamiento local y lo utiliza para crear tweets.

## 🏗️ Estructura de Archivos Creados

```
lib/
├── models/
│   ├── user.dart                 [NUEVO] Modelo de Usuario
│   ├── tweet.dart               
│   └── tweet_response.dart       
├── services/
│   ├── auth_service.dart         [NUEVO] Servicio de Autenticación
│   └── tweet_service.dart        [MODIFICADO] Ahora usa Bearer token
├── screens/
│   └── login_screen.dart         [NUEVO] Pantalla de Login
├── main.dart                      [MODIFICADO] Navegación sin registro
└── pubspec.yaml                   [MODIFICADO] Agregado shared_preferences
```

## 🔐 Flujo de Autenticación

```
┌─────────────────────────────────────────────────────────┐
│ Inicio de Aplicación                                    │
│ ↓                                                       │
│ ¿Token guardado en SharedPreferences?                  │
│ ├─ SÍ → MyHomePage (Twitter Feed) ✓                   │
│ └─ NO → LoginScreen                                    │
│         ├─ Usuario: admin                              │
│         ├─ Contraseña: 12345678                        │
│         └─ POST /api/auth/signin                       │
│            ├─ ✓ Éxito → Guardar token+usuario         │
│            ├─ Navegar a MyHomePage                     │
│            └─ ✗ Error → Mostrar mensaje de error       │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Cómo Probar

### Paso 1: Compilar la app
```bash
cd /home/adsoft/Desktop/2026/usbi/principios/tweeter-front
flutter pub get
flutter run
```

### Paso 2: Login
1. La app mostrará la pantalla de Login
2. Las credenciales están pre-rellenadas:
   - Usuario: `admin`
   - Contraseña: `12345678`
3. Presiona "Iniciar Sesión"
4. Se enviará un POST a `http://localhost:8080/api/auth/signin`

### Paso 3: Crear Tweets
1. Après el login exitoso, verás MyHomePage
2. En la AppBar verás: "Usuario: admin"
3. Escribe un tweet en el campo de texto
4. Presiona "Post Tweet"
5. La app enviará un POST a `http://localhost:8080/api/tweets/create` con:
   ```json
   {
     "Authorization": "Bearer {token}",
     "Content-Type": "application/json"
   }
   ```

### Paso 4: Logout
1. Presiona el menú (⋮) en la esquina superior derecha
2. Selecciona "Cerrar Sesión"
3. Serás redirigido al LoginScreen
4. El token se elimina del almacenamiento local

## 📡 APIs Utilizadas

### 1. Autenticación (Login)
```
POST http://localhost:8080/api/auth/signin
Content-Type: application/json

REQUEST:
{
  "username": "admin",
  "password": "12345678"
}

RESPONSE (200 OK):
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "username": "admin",
    "email": "admin@example.com"
  }
}
```

### 2. Crear Tweet (Requiere Bearer Token)
```
POST http://localhost:8080/api/tweets/create
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

REQUEST:
{
  "tweet": "Contenido del tweet aquí"
}

RESPONSE (200 OK):
{
  "id": 123,
  "tweet": "Contenido del tweet aquí",
  "createdAt": "2026-04-15T10:30:00Z"
}
```

## 💾 Almacenamiento Local (SharedPreferences)

Los siguientes datos se guardan automáticamente:

```dart
// Cuando el login es exitoso:
_prefs.setString('auth_token', token_value);
_prefs.setString('auth_user', user_json);

// Cuando el usuario hace logout:
_prefs.remove('auth_token');
_prefs.remove('auth_user');
```

## 🔄 Ciclo de Vida de la Autenticación

### Login Exitoso:
1. POST a `/api/auth/signin`
2. Recibe token y user
3. Guarda token en SharedPreferences
4. Guarda user en SharedPreferences
5. Navega a MyHomePage
6. El token se usa automáticamente en todas las requests

### Logout:
1. Usuario presiona "Cerrar Sesión"
2. Se eliminan auth_token y auth_user de SharedPreferences
3. Se navega a LoginScreen
4. El usuario debe hacer login nuevamente

### Persistencia:
- Si cierras la app y la reopres, el token sigue existiendo
- La app verificará en init() si hay token guardado
- Si existe, irá directamente a MyHomePage sin pasar por login
- Si no existe, mostrará LoginScreen

## ⚙️ Clases Principales

### AuthService.dart
```dart
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  
  // Métodos principales:
  login(username, password)     // Autentica y guarda token
  getToken()                     // Obtiene token guardado
  getUser()                      // Obtiene usuario guardado
  isAuthenticated()              // ¿Existe sesión activa?
  logout()                       // Borra token y usuario
}
```

### TweetService.dart (Modificado)
```dart
class TweetService {
  // Ahora integrado con AuthService
  _getHeaders()         // Agrega token Bearer automáticamente
  createTweet(content)  // Usa /tweets/create con token
  fetchTweets()         // Incluye token en headers
  deleteTweet(id)       // Incluye token en headers
}
```

## 🎨 Pantallas

### LoginScreen
- Interfaz limpia y profesional
- Pre-rellenada con credenciales de prueba
- Indicador de carga durante autenticación
- Mensajes de error informativos
- Info de credenciales de prueba visible

### MyHomePage
- AppBar mejorado con:
  - Nombre del usuario autenticado
  - Botón de logout
- Crear tweets con token Bearer automático
- Listar tweets autenticado
- Eliminar tweets autenticado

## 🧪 Casos de Prueba Sugeridos

| # | Caso | Pasos | Resultado Esperado |
|---|------|-------|-------------------|
| 1 | Login válido | Usa admin/12345678 | Navega a MyHomePage ✓ |
| 2 | Login inválido | Usa credenciales falsas | Muestra error ✓ |
| 3 | Crear tweet | Post Tweet con contenido | Tweet aparece en la lista ✓ |
| 4 | Logout | Presiona Cerrar Sesión | Navega a LoginScreen ✓ |
| 5 | Persistencia | Cierra app, reabre | Mantiene sesión activa ✓ |
| 6 | Token en request | Inspecciona headers | Authorization: Bearer... ✓ |
| 7 | Listar tweets | Tras login | Muestra tweets autenticado ✓ |
| 8 | Eliminar tweet | Click delete | Tweet se elimina ✓ |

## 📝 Ejemplo de Headers Enviados

Cuando creas un tweet después de autenticarte:

```
POST /api/tweets/create HTTP/1.1
Host: localhost:8080
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwibmFtZSI6ImFkbWluIiwiaWF0IjoxNTE2MjM5MDIyfQ.R9m_huv4c_qPYs1llW...

{
  "tweet": "Mi primer tweet autenticado!"
}
```

## 🐛 Solución de Problemas

### Problema: "No authentication token found"
**Solución**: Debes hacer login primero. El token se obtiene de `/api/auth/signin`

### Problema: "Invalid token" al crear tweet
**Solución**: El token puede estar expirado. Haz logout y login de nuevo.

### Problema: SharedPreferences vacío
**Solución**: Esto es normal en primera ejecución. Login generará y guardará el token.

### Problema: No puedo crear tweets sin login
**Solución**: Es correcto. El endpoint `/tweets/create` requiere token Bearer válido.

## ✅ Checklist de Validación

- [x] Pantalla de login creada
- [x] Autenticación con API integrada
- [x] Token guardado en SharedPreferences
- [x] Token usado en request de tweets
- [x] Bearer authentication configurado
- [x] Logout implementado
- [x] Navegación condicional según autenticación
- [x] Información del usuario mostrada en UI
- [x] Persistencia de sesión entre reinicios
- [x] Manejo de errores implementado

## 🎯 Próximas Mejoras Opcionales

1. Refresh token automático
2. Interceptor de errores HTTP 401
3. Cierre de sesión por timeout
4. Validación de campos en login
5. Animaciones de transición
6. Indicador de conexión
7. Modo offline con caché
8. Two-factor authentication
