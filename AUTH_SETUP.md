# Guía de Implementación - Autenticación y Tweets

## Cambios Realizados

### 1. Actualización de dependencias (`pubspec.yaml`)
Se agregó la dependencia `shared_preferences: ^2.2.2` para guardar el token de autenticación de manera persistente.

### 2. Archivos Creados

#### **lib/models/user.dart**
- Modelo `User` que representa un usuario autenticado
- Incluye serialización/deserialización JSON

#### **lib/services/auth_service.dart**
- Servicio Singleton para gestionar autenticación
- Métodos principales:
  - `login(username, password)` - Autentica con la API
  - `getToken()` - Obtiene el token guardado
  - `getUser()` - Obtiene el usuario guardado
  - `isAuthenticated()` - Verifica si existe sesión activa
  - `logout()` - Cierra sesión y limpia datos

#### **lib/screens/login_screen.dart**
- Pantalla de login completa
- Pre-rellenada con credenciales de prueba (admin/12345678)
- Manejo de errores con feedback visual
- Navegación a la pantalla principal tras login exitoso

### 3. Archivos Modificados

#### **lib/services/tweet_service.dart**
- Integración con `AuthService`
- Método `_getHeaders()` que agrega token Bearer a los headers
- Actualización de endpoints:
  - `createTweet()` usa `/tweets/create` con token Bearer
  - `fetchTweets()` incluye token en headers
  - `deleteTweet()` incluye token en headers

#### **lib/main.dart**
- Inicialización de `SharedPreferences` en `main()`
- Implementación de redireccionamiento basado en autenticación
- Rutas nombradas: `/login` y `/home`
- AppBar con información del usuario y botón de logout
- Método `_logout()` para cerrar sesión

## Flujo de Funcionamiento

```
app_start
    ↓
init_auth_service (carga SharedPreferences)
    ↓
check_authentication ✓
    ├─ YES → MyHomePage (Twitter Feed)
    └─ NO  → LoginScreen
              ↓
            login(admin, 12345678)
              ↓
            save_token & user
              ↓
            navigate_to_home
              ↓
            MyHomePage (con token en headers)
```

## API Endpoints Utilizados

### Autenticación
```
POST http://localhost:8080/api/auth/signin
Headers: {"Content-Type": "application/json"}
Body: {"username": "admin", "password": "12345678"}
Response: {"token": "...", "user": {"id": ..., "username": "admin", ...}}
```

### Crear Tweet
```
POST http://localhost:8080/api/tweets/create
Headers: {
  "Content-Type": "application/json",
  "Authorization": "Bearer {token}"
}
Body: {"tweet": "contenido del tweet"}
```

## Credenciales de Prueba

- **Usuario:** admin
- **Contraseña:** 12345678

(Las credenciales se pre-rellenan automáticamente en la pantalla de login)

## Pruebas Recomendadas

1. **Login**: Ingresa con admin/12345678
2. **Crear Tweet**: Escribe un tweet y presiona "Post Tweet"
3. **Ver Token**: El token se guarda automáticamente en SharedPreferences
4. **Logout**: Usa el menú superior para cerrar sesión
5. **Persistencia**: Cierra la app y reabre - deberías mantener la sesión

## Almacenamiento Local

Los siguientes datos se guardan en `SharedPreferences`:
- `auth_token` - Token JWT para Bearer authentication
- `auth_user` - Datos del usuario autenticado (JSON)

## Seguridad

- El token se almacena localmente en SharedPreferences (seguro en dispositivos)
- Se pasa como `Bearer token` en el header `Authorization`
- El logout limpia ambas referencias del almacenamiento

## Próximos Pasos Opcionales

1. Implementar refresh token para expiración
2. Agregar interceptor de errores HTTP 401
3. Implementar cierre de sesión automática por timeout
4. Agregar validación de campos en el login
5. Mejorar la UI con animaciones
