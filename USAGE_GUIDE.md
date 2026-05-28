# Guía de Uso y Ejemplos

## Uso de TweetService

### Obtener la instancia

```dart
// Opción 1: Constructor factory
final tweetService = TweetService();

// Opción 2: Método estático
final tweetService = TweetService.getInstance();

// RESULTADO: La misma instancia (Singleton) ✓
```

---

## Operaciones CRUD

### 1. Obtener todos los tweets

```dart
try {
  final tweets = await tweetService.fetchTweets();
  
  for (final tweet in tweets) {
    print('Tweet ID ${tweet.id}: ${tweet.tweet}');
  }
} catch (e) {
  print('Error: $e');
}
```

**Respuesta esperada:**
```
Tweet ID 1: Hola Flutter!
Tweet ID 2: Patrón Singleton
Tweet ID 3: SOLID rules
```

---

### 2. Crear un nuevo tweet

```dart
try {
  final newTweet = await tweetService.createTweet(
    'Este es mi primer tweet desde Flutter'
  );
  
  print('Tweet creado:');
  print('ID: ${newTweet.id}');
  print('Contenido: ${newTweet.tweet}');
  
} catch (e) {
  print('Error al crear: $e');
}
```

**Validaciones:**
```dart
// ❌ Falla: contenido vacío
await tweetService.createTweet('');

// ✓ Éxito: contenido válido
await tweetService.createTweet('Mi nuevo tweet');

// ✓ Éxito: largo
await tweetService.createTweet('Este es un tweet muy largo...');
```

---

### 3. Eliminar un tweet

```dart
try {
  await tweetService.deleteTweet(123);
  print('Tweet eliminado correctamente');
  
} catch (e) {
  print('Error al eliminar: $e');
}
```

---

## Flujo Completo en la UI

### Ejemplo 1: Crear y Actualizar

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _tweetService = TweetService();
  final _controller = TextEditingController();

  void _handlePostTweet() async {
    try {
      // 1. Crear tweet
      final tweet = await _tweetService.createTweet(
        _controller.text
      );
      
      // 2. Limpiar input
      _controller.clear();
      
      // 3. Actualizar UI (auto-refresh)
      setState(() {
        // La lista se recarga automáticamente
      });
      
      // 4. Mostrar confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tweet creado: ${tweet.id}'))
      );
      
    } catch (e) {
      _showError('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(controller: _controller),
        ElevatedButton(
          onPressed: _handlePostTweet,
          child: Text('Post'),
        ),
      ],
    );
  }
}
```

### Ejemplo 2: Eliminar con Confirmación

```dart
void _handleDeleteTweet(int tweetId) async {
  // 1. Confirmar
  final confirmed = await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('¿Eliminar tweet?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Eliminar', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (!confirmed) return;

  try {
    // 2. Eliminar
    await _tweetService.deleteTweet(tweetId);
    
    // 3. Actualizar UI
    setState(() {
      // Recarga automática
    });
    
    // 4. Confirmar al usuario
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tweet eliminado'),
        backgroundColor: Colors.green,
      )
    );
    
  } catch (e) {
    _showError('Error: $e');
  }
}
```

---

## Manejo de Errores

### Validaciones Built-in

```dart
// El servicio valida automáticamente:

// ❌ Tweet vacío
await tweetService.createTweet('');
// Excepción: "Tweet content cannot be empty"

// ❌ ID inválido
await tweetService.deleteTweet(-1);
// Excepción: HTTP 404 o similar

// ❌ Sin conexión
await tweetService.fetchTweets();
// Excepción: "Error fetching tweets: ..."
```

### Implementar Reintentos

```dart
Future<List<Tweet>> fetchTweetsWithRetry({
  int maxRetries = 3,
  Duration delay = const Duration(seconds: 1),
}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await _tweetService.fetchTweets();
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(delay * (i + 1));
    }
  }
  throw Exception('Max retries exceeded');
}
```

---

## Testing con Mocks

### Mock Implementation

```dart
class MockTweetRepository implements ITweetRepository {
  final List<Tweet> _tweets = [
    Tweet(id: 1, tweet: 'Test tweet 1'),
    Tweet(id: 2, tweet: 'Test tweet 2'),
  ];
  
  int _nextId = 3;

  @override
  Future<List<Tweet>> fetchTweets() async {
    await Future.delayed(Duration(milliseconds: 100));
    return _tweets;
  }

  @override
  Future<Tweet> createTweet(String content) async {
    if (content.isEmpty) {
      throw Exception('Content cannot be empty');
    }
    
    final tweet = Tweet(id: _nextId++, tweet: content);
    _tweets.add(tweet);
    return tweet;
  }

  @override
  Future<void> deleteTweet(int id) async {
    _tweets.removeWhere((t) => t.id == id);
  }

  @override
  void dispose() {
    // Mock cleanup
  }
}
```

### Pruebas Unitarias

```dart
void main() {
  group('TweetService Tests', () {
    late MockTweetRepository repository;

    setUp(() {
      repository = MockTweetRepository();
    });

    test('fetchTweets returns list', () async {
      final tweets = await repository.fetchTweets();
      expect(tweets, isNotEmpty);
      expect(tweets.length, equals(2));
    });

    test('createTweet adds new tweet', () async {
      final initialCount = (await repository.fetchTweets()).length;
      
      await repository.createTweet('New tweet');
      
      final finalCount = (await repository.fetchTweets()).length;
      expect(finalCount, equals(initialCount + 1));
    });

    test('createTweet validates content', () async {
      expect(
        () => repository.createTweet(''),
        throwsException,
      );
    });

    test('deleteTweet removes tweet', () async {
      await repository.deleteTweet(1);
      
      final tweets = await repository.fetchTweets();
      expect(
        tweets.where((t) => t.id == 1),
        isEmpty,
      );
    });
  });
}
```

---

## Integración en la App

### En main.dart

```dart
@override
void initState() {
  super.initState();
  
  // Singleton garantiza una única instancia
  _tweetService = TweetService();
  
  // Primera carga
  _loadTweets();
}

void _loadTweets() {
  setState(() {
    _tweetsFuture = _tweetService.fetchTweets();
  });
}

Future<void> _createTweet() async {
  final content = _tweetController.text.trim();
  
  if (content.isEmpty) {
    _showErrorDialog('Cannot be empty');
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Crear
    await _tweetService.createTweet(content);
    
    // Limpiar
    _tweetController.clear();
    
    // Auto-refresh
    _loadTweets();
    
    // Feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tweet created!'))
    );
  } catch (e) {
    _showErrorDialog('Error: $e');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

Future<void> _deleteTweet(int id) async {
  setState(() => _isLoading = true);

  try {
    // Eliminar
    await _tweetService.deleteTweet(id);
    
    // Auto-refresh
    _loadTweets();
    
    // Feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tweet deleted!'))
    );
  } catch (e) {
    _showErrorDialog('Error: $e');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

@override
void dispose() {
  _tweetController.dispose();
  _tweetService.dispose(); // Cleanup
  super.dispose();
}
```

---

## Escalabilidad Futura

### Fácil agregar Cache

```dart
class CachedTweetRepository implements ITweetRepository {
  final ITweetRepository _delegate;
  List<Tweet>? _cache;

  CachedTweetRepository(this._delegate);

  @override
  Future<List<Tweet>> fetchTweets() async {
    return _cache ??= await _delegate.fetchTweets();
  }

  @override
  Future<Tweet> createTweet(String content) async {
    final tweet = await _delegate.createTweet(content);
    _cache = null; // Invalidar cache
    return tweet;
  }

  @override
  Future<void> deleteTweet(int id) async {
    await _delegate.deleteTweet(id);
    _cache = null; // Invalidar cache
  }

  @override
  void dispose() => _delegate.dispose();
}
```

### Uso con Cache

```dart
// Crear instancia con cache
final repository = CachedTweetRepository(TweetService());

// Usar igual que antes
final tweets = await repository.fetchTweets();
```

---

## Checklist de Implementación

- ✓ Interfaz `ITweetRepository` definida
- ✓ `TweetService` implementa interfaz
- ✓ Métodos `createTweet()` y `deleteTweet()` agregados
- ✓ Auto-refresh después de operaciones
- ✓ UI actualizada con crear/eliminar
- ✓ Manejo de errores y validaciones
- ✓ Feedback visual (SnackBars, Dialogs)
- ✓ Spinner de loading
- ✓ Confirmación antes de eliminar
- ✓ Código sigue SOLID
- ✓ Fácil testeable con mocks

---

## Resumen de Mejoras

| Característica | Antes | Después |
|---|---|---|
| **CRUD Completo** | Solo READ | ✓ CREATE, READ, DELETE |
| **Auto-refresh** | Manual | ✓ Automático |
| **UI** | Básica | ✓ Completa |
| **Testing** | Difícil | ✓ Fácil con mocks |
| **Mantenibilidad** | Media | ✓ Alta |
| **Extensibilidad** | Baja | ✓ Alta |
| **Principios SOLID** | Parcial | ✓ Completo |

