# Diagrama de Arquitectura Refactorizada

## Estructura de Componentes

```
┌─────────────────────────────────────────────────────────────┐
│                      UI LAYER (main.dart)                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  MyHomePage (State Management)                       │   │
│  │  ├── _buildCreateTweetSection()     [Agregar tweets] │   │
│  │  ├── _buildTweetCard()              [Mostrar tweets] │   │
│  │  ├── _createTweet()                 [Crear]          │   │
│  │  ├── _deleteTweet()                 [Eliminar]       │   │
│  │  └── _loadTweets()                  [Refresh]        │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              ↓
                         Depende de:
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    REPOSITORY LAYER                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  <<interface>> ITweetRepository                      │   │
│  │  ├── fetchTweets(): Future<List<Tweet>>             │   │
│  │  ├── createTweet(String): Future<Tweet>             │   │
│  │  ├── deleteTweet(int): Future<void>                 │   │
│  │  └── dispose(): void                                 │   │
│  └──────────────────────────────────────────────────────┘   │
│                              ↑                                │
│                      Implementado por:                        │
│                              ↓                                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  TweetService (Singleton + Repository Pattern)      │   │
│  │  ├── fetchTweets()      [DIP]                        │   │
│  │  ├── createTweet()      [SRP]                        │   │
│  │  ├── deleteTweet()      [SRP]                        │   │
│  │  ├── _parseGetTweetsResponse() [OCP]               │   │
│  │  ├── _parseTweetResponse()    [OCP]                │   │
│  │  └── dispose()                                       │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              ↓
                         Usa HTTP:
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   HTTP CLIENT LAYER                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  http.Client                                         │   │
│  │  - GET    /api/tweets         → fetchTweets()       │   │
│  │  - POST   /api/tweets         → createTweet()       │   │
│  │  - DELETE /api/tweets/{id}    → deleteTweet()       │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    MODELS LAYER                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Tweet                                               │   │
│  │  ├── id: int                                          │   │
│  │  ├── tweet: String                                    │   │
│  │  └── toJson()/fromJson()                             │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  TweetResponse                                        │   │
│  │  ├── content: List<Tweet>                            │   │
│  │  └── fromJson()                                       │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Flujo de Datos: Agregar Tweet (Ejemplo)

```
1. Usuario escribe en TextField
   ↓
2. Presiona botón "Post Tweet"
   ↓
3. _createTweet() valida contenido [SRP]
   ↓
4. TweetService.createTweet() [DIP - depende de abstracción]
   ↓
5. HTTP POST a "/api/tweets" [ISP]
   ↓
6. _parseTweetResponse() extrae datos [SRP]
   ↓
7. Retorna Tweet nuevo [LSP - implementa ITweetRepository]
   ↓
8. _loadTweets() auto-refresh [OCP - código abierto a extensión]
   ↓
9. UI actualizada con nuevo tweet [Single Responsibility]
```

---

## Principios SOLID en Acción

```
┌──────────────────────────────────────────────────────────┐
│                  SINGLE RESPONSIBILITY                   │
│                                                          │
│  _parseGetTweetsResponse()  →  Solo parsing GET         │
│  _parseTweetResponse()      →  Solo parsing POST        │
│  fetchTweets()              →  Solo fetch               │
│  createTweet()              →  Solo crear               │
│  deleteTweet()              →  Solo eliminar            │
│  _buildTweetCard()          →  Solo render card         │
│  _buildCreateTweetSection() →  Solo render form         │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│                  OPEN/CLOSED PRINCIPLE                   │
│                                                          │
│  ✓ Abierto para extensión:                             │
│    - Nuevo método deleteTweet() sin tocar fetchTweets   │
│    - Nueva UI sin tocar lógica de servicio              │
│                                                          │
│  ✓ Cerrado para modificación:                           │
│    - fetchTweets() no cambió                            │
│    - Métodos privados encapsulan detalles              │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│              LISKOV SUBSTITUTION PRINCIPLE                │
│                                                          │
│  TweetService implementa ITweetRepository               │
│  Puede ser reemplazado por:                             │
│    - MockTweetRepository (testing)                      │
│    - CachedTweetRepository (caching)                    │
│    - CloudTweetRepository (cloud)                       │
│                                                          │
│  Todo sin quebrar el código cliente ✓                   │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│              INTERFACE SEGREGATION PRINCIPLE              │
│                                                          │
│  ITweetRepository solo define:                          │
│    - fetchTweets()  ✓ Necesario                         │
│    - createTweet()  ✓ Necesario                         │
│    - deleteTweet()  ✓ Necesario                         │
│    - dispose()      ✓ Necesario                         │
│                                                          │
│  NO implementa métodos innecesarios ✓                   │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│               DEPENDENCY INVERSION PRINCIPLE              │
│                                                          │
│  ANTES (Acoplado):                                      │
│    class UI {                                            │
│      TweetService _service; // Depende de implementación│
│    }                                                     │
│                                                          │
│  DESPUÉS (Desacoplado):                                 │
│    class UI {                                            │
│      ITweetRepository _repo; // Depende de abstracción  │
│    }                                                     │
│                                                          │
│  ✓ Bajo acoplamiento, fácil de testear                 │
└──────────────────────────────────────────────────────────┘
```

---

## Patrones de Diseño Visualizados

### Singleton Pattern
```
┌──────────────────────────────────┐
│    TweetService (Singleton)      │
│  static final _instance = ...    │
│  private constructor()           │
│  factory TweetService()          │
│  getInstance()                   │
│                                  │
│  Resultado:                      │
│  ≡ Una única instancia global   │
│  ≡ Acceso desde cualquier lado   │
│  ≡ Ciclo de vida controlado      │
└──────────────────────────────────┘
```

### Repository Pattern
```
┌─────────────────────────────┐
│   ITweetRepository          │ (Abstracción)
│ + fetchTweets()             │
│ + createTweet()             │
│ + deleteTweet()             │
│ + dispose()                 │
└──────────────┬──────────────┘
               ▲
               │ implementa
               │
┌──────────────┴──────────────┐
│    TweetService             │ (Implementación)
│  (HTTP, Singleton)          │
│ + fetchTweets()             │
│ + createTweet()             │
│ + deleteTweet()             │
│ + dispose()                 │
└─────────────────────────────┘

Ventajas:
✓ Abstrae capa de datos
✓ Permite múltiples implementaciones
✓ Facilita testing
✓ Desacoplamiento
```

---

## Auto-Refresh Implementation

```
┌──────────────────────────────────────────────────┐
│           User Interaction                       │
└────────────────┬─────────────────────────────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
    ▼            ▼            ▼
┌────────┐ ┌─────────┐ ┌──────────┐
│ Agregar│ │Eliminar │ │  Refresh │
│ Tweet  │ │ Tweet   │ │ Button   │
└────┬───┘ └────┬────┘ └─────┬────┘
     │          │            │
     └──────────┼────────────┘
                │
                ▼
       ┌─────────────────┐
       │ _loadTweets()   │
       └────────┬────────┘
                │
                ▼
       ┌──────────────────────┐
       │ setState(() => {      │
       │   _tweetsFuture =    │
       │ service.fetchTweets()│
       │ })                    │
       └────────┬─────────────┘
                │
                ▼
       ┌──────────────────────┐
       │ FutureBuilder widget  │
       │ reconstruye lista     │
       └──────────────────────┘
```

---

## Manejo de Estados

```
OPERACIÓN: Crear Tweet

┌─────────────────────────────────┐
│ _isLoading = false              │
│ Solo lectura posible            │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│ Usuario presiona "Post Tweet"   │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│ setState(() =>                   │
│   _isLoading = true)            │
│ Desabilita botones              │
│ Muestra loading spinner         │
└──────────┬──────────────────────┘
           │
           ▼ HTTP POST
┌─────────────────────────────────┐
│ TweetService.createTweet()      │
└──────────┬──────────────────────┘
           │
           ├──> SUCCESS
           │    ├─ Limpia TextField
           │    ├─ Llama _loadTweets()
           │    ├─ Muestra SnackBar verde
           │    └─ _isLoading = false
           │
           └──> ERROR
                ├─ Muestra AlertDialog
                └─ _isLoading = false
```

---

## Mejoras Visuales

### Antes vs Después

```
ANTES:
┌──────────────────────────┐
│                          │
│  [Refresh Button]        │
│                          │
│  ┌────────────────────┐  │
│  │ Tweet 1            │  │
│  │ ID: 123            │  │
│  └────────────────────┘  │
│  ┌────────────────────┐  │
│  │ Tweet 2            │  │
│  │ ID: 124            │  │
│  └────────────────────┘  │
│                          │
└──────────────────────────┘

DESPUÉS:
┌─────────────────────────────────┐
│ ┌─────────────────────────────┐  │
│ │ ✎ What's on your mind?     │  │  ← Nuevo
│ │                             │  │
│ │                             │  │
│ │ [Post Tweet]                │  │  ← Nuevo
│ └─────────────────────────────┘  │
│                                  │
│ ┌─────────────────────────────┐  │
│ │ Tweet 1              [✕]    │  │  ← Delete button
│ │ ID: 123                     │  │
│ └─────────────────────────────┘  │
│ ┌─────────────────────────────┐  │
│ │ Tweet 2              [✕]    │  │  ← Delete button
│ │ ID: 124                     │  │
│ └─────────────────────────────┘  │
│                                  │
│        [↻ Refresh]               │
└─────────────────────────────────┘
```

---

## Resumen de Cambios

| Archivo | Cambio | Impacto |
|---------|--------|--------|
| `tweet_repository.dart` | ✓ NUEVO | Define interfaz (DIP) |
| `tweet_service.dart` | ✓ REFACTORIZADO | Implementa interfaz + CRUD |
| `main.dart` | ✓ AMPLIADO | Agregar/Eliminar tweets |
| `tweet.dart` | - Sin cambios | Compatible |
| `tweet_response.dart` | - Sin cambios | Compatible |

---

## Testing Facilitado por Refactorización

```dart
// FÁCIL de testear ahora:

void main() {
  group('TweetService', () {
    test('creates tweet', () async {
      final service = MockTweetRepository();
      final tweet = await service.createTweet('Test');
      expect(tweet.tweet, equals('Test'));
    });

    test('deletes tweet', () async {
      final service = MockTweetRepository();
      await service.deleteTweet(1);
      // Sin excepciones = éxito
    });
  });
}
```

✓ Interfaz limpia facilita mocks
✓ Métodos especializados son testables
✓ Sin dependencias externas en pruebas
