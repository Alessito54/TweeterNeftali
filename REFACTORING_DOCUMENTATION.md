# Refactorización de Tweet Service - Patrones de Diseño y Principios SOLID

## Cambios Realizados

### 1. **Inyección de Dependencias - Repository Pattern**

Se creó una interfaz abstracta `ITweetRepository` que define el contrato para todas las operaciones de datos.

```dart
abstract class ITweetRepository {
  Future<List<Tweet>> fetchTweets();
  Future<Tweet> createTweet(String content);
  Future<void> deleteTweet(int id);
  void dispose();
}
```

**Beneficios:**
- Permite cambiar entre diferentes implementaciones (HTTP, local, mock) sin afectar el cliente
- Facilita pruebas unitarias con mocks
- Mejora la mantenibilidad

---

## Principios SOLID Aplicados

### **S - Single Responsibility Principle (SRP)**

#### Antes:
- `TweetService` mezclaba lógica de HTTP, parsing JSON y ciclo de vida

#### Después:
- Se extrajeron métodos privados especializados:
  - `_parseGetTweetsResponse()`: Responsable solo del parsing de GET
  - `_parseTweetResponse()`: Responsable solo del parsing de POST
  - Cada método HTTP (`fetchTweets`, `createTweet`, `deleteTweet`) tiene una responsabilidad clara

```dart
// Método privado especializado en parsing de respuestas GET
List<Tweet> _parseGetTweetsResponse(String responseBody) {
  final jsonData = jsonDecode(responseBody) as Map<String, dynamic>;
  final tweetResponse = TweetResponse.fromJson(jsonData);
  return tweetResponse.content;
}
```

---

### **O - Open/Closed Principle (OCP)**

#### Implementación:
- El servicio está **abierto para extensión** pero **cerrado para modificación**
- Se pueden agregar nuevos métodos sin cambiar los existentes
- Ejemplo: Se agregaron `createTweet()` y `deleteTweet()` sin modificar `fetchTweets()`

```dart
@override
Future<Tweet> createTweet(String content) async {
  // Nueva funcionalidad sin tocar código existente
}
```

---

### **L - Liskov Substitution Principle (LSP)**

#### Implementación:
- `TweetService` implementa `ITweetRepository`
- Puede usarse cualquier implementación de `ITweetRepository` sin conocer los detalles

```dart
class TweetService implements ITweetRepository {
  // Cumple completamente el contrato de ITweetRepository
}
```

---

### **I - Interface Segregation Principle (ISP)**

#### Implementación:
- `ITweetRepository` define solo las operaciones necesarias (métodos es específicos)
- No obliga a implementar métodos innecesarios
- Cada método es una responsabilidad clara

```dart
abstract class ITweetRepository {
  Future<List<Tweet>> fetchTweets();        // Solo lo necesario
  Future<Tweet> createTweet(String content); // Segregado
  Future<void> deleteTweet(int id);         // Segregado
  void dispose();
}
```

---

### **D - Dependency Inversion Principle (DIP)**

#### Implementación:
- El código depende de abstracciones (`ITweetRepository`), no de implementaciones concretas
- `TweetService` implementa la interfaz, permitiendo polimorfismo

```dart
// Depender de la abstracción
late ITweetRepository _repository;

// En lugar de:
// late TweetService _service; // Esto sería tightly coupled
```

---

## Patrones de Diseño Utilizados

### 1. **Singleton Pattern**
- Garantiza una única instancia de `TweetService` en toda la aplicación
- Acceso global mediante `TweetService.getInstance()`

```dart
static final TweetService _instance = TweetService._internal();

factory TweetService() {
  return _instance;
}
```

### 2. **Repository Pattern**
- Abstrae la capa de acceso a datos
- Permite cambiar la fuente de datos sin afectar la lógica de negocio

```dart
abstract class ITweetRepository {
  // Contrato de operaciones CRUD
}

class TweetService implements ITweetRepository {
  // Implementación concreta
}
```

### 3. **Strategy Pattern (Implícito)**
- Diferentes estrategias de HTTP (GET, POST, DELETE)
- Cada método usa la estrategia HTTP apropiada

---

## Mejoras en la UI (main.dart)

### 1. **Funcionalidades Nuevas**

#### a) Agregar Tweets
```dart
_buildCreateTweetSection()
```
- Campo de texto para escrib ir tweets
- Botón "Post Tweet" para enviar
- Validación de contenido vacío

#### b) Eliminar Tweets
```dart
_showDeleteConfirmation(int id)
_deleteTweet(int id)
```
- Botón de eliminar en cada tarjeta
- Confirmación antes de eliminar
- Auto-refresh después de eliminar

### 2. **Refresh Automático**

```dart
Future<void> _createTweet() async {
  // ... crear tweet
  _loadTweets(); // Auto-refresh ✓
}

Future<void> _deleteTweet(int id) async {
  // ... eliminar tweet
  _loadTweets(); // Auto-refresh ✓
}
```

### 3. **Mejor Manejo de Estados**

```dart
bool _isLoading = false;

// Feedback visual al user
setState(() => _isLoading = true);
try {
  // Operación
} finally {
  setState(() => _isLoading = false);
}
```

### 4. **Métodos Privados Especializados**

```dart
Widget _buildCreateTweetSection()  // Componente reutilizable
Widget _buildTweetCard(Tweet tweet) // Tarjeta reutilizable
void _showDeleteConfirmation()    // Diálogo separado
void _showErrorDialog()           // Error handling separado
```

---

## Ventajas de la Refactorización

| Aspecto | Antes | Después |
|--------|-------|---------|
| **Testabilidad** | Difícil, acoplado | Fácil, con mocks |
| **Extensibilidad** | Modificar Service | Que nueva clase |
| **Mantenibilidad** | Alto acoplamiento | Bajo acoplamiento |
| **Reusabilidad** | Limitada | Alta (interfaz) |
| **Responsabilidades** | Mezcladas | Separadas |

---

## Estructura de Directorios

```
lib/
  ├── main.dart                    # UI mejorada
  ├── models/
  │   ├── tweet.dart              # Sin cambios
  │   └── tweet_response.dart      # Sin cambios
  ├── repositories/
  │   └── tweet_repository.dart    # Nueva interfaz (SRP, DIP)
  ├── services/
  │   └── tweet_service.dart       # Refactorizado con CRUD completo
```

---

## Cómo Usar

### Crear Tweet
```dart
await _tweetService.createTweet('Mi nuevo tweet');
```

### Eliminar Tweet
```dart
await _tweetService.deleteTweet(tweetId);
```

### Fetch Tweets
```dart
final tweets = await _tweetService.fetchTweets();
```

---

## Testing (Ejemplo)

Ahora es fácil crear un mock:

```dart
class MockTweetRepository implements ITweetRepository {
  @override
  Future<List<Tweet>> fetchTweets() async {
    return [Tweet(id: 1, tweet: 'Test tweet')];
  }

  @override
  Future<Tweet> createTweet(String content) async {
    return Tweet(id: 2, tweet: content);
  }

  @override
  Future<void> deleteTweet(int id) async {}

  @override
  void dispose() {}
}
```

---

## Conclusión

La refactorización aplica:
- ✅ **Principios SOLID** completos
- ✅ **Patrones de diseño** (Singleton, Repository)
- ✅ **Separación de responsabilidades**
- ✅ **Mejor mantenibilidad y testabilidad**
- ✅ **UI mejorada con CRUD completo**
- ✅ **Auto-refresh después de operaciones**
