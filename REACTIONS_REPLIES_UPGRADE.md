# 🚀 Upgrade de Twetter: Reacciones y Respuestas

## ✅ Cambios Implementados

Este upgrade agrega funcionalidad completa para que los usuarios puedan **reaccionar con emojis** y **responder** a los posts, como en una red social normal.

---

## 🎯 Nuevas Características

### 1. **Reacciones con Emojis**
- Los usuarios pueden reaccionar a cualquier post con 6 emojis diferentes:
  - 👍 Pulgar arriba
  - ❤️ Corazón
  - 😂 Risa
  - 😢 Triste
  - 🔥 Fuego
  - 🎉 Celebración

- Al hacer clic en un emoji, se **agrega** la reacción
- Al hacer clic de nuevo en el mismo emoji, se **elimina** (toggle)
- Se muestra el **número de reacciones** por emoji
- Las reacciones del usuario actual se destacan visualmente

### 2. **Respuestas (Replies)**
- Los usuarios pueden escribir respuestas a cualquier post
- Cada post muestra cuántas respuestas tiene
- Las respuestas se pueden **expandir/colapsar**
- Cada respuesta muestra:
  - Usuario que respondió
  - Texto de la respuesta
  - Fecha/hora
  - Botón de eliminar (solo autor y admin)
- Campo de entrada para nueva respuesta en tiempo real

---

## 🔄 Cambios en la Base de Datos

### Nuevas Tablas

#### `reactions`
```sql
CREATE TABLE reactions (
  id INTEGER PRIMARY KEY,
  emoji VARCHAR(10) NOT NULL,
  tweetId INTEGER NOT NULL REFERENCES tweets(id) ON DELETE CASCADE,
  userId INTEGER NOT NULL REFERENCES users(id),
  createdAt TIMESTAMP DEFAULT NOW(),
  UNIQUE(tweetId, userId, emoji)
);
```

#### `replies`
```sql
CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  text TEXT NOT NULL,
  tweetId INTEGER NOT NULL REFERENCES tweets(id) ON DELETE CASCADE,
  userId INTEGER NOT NULL REFERENCES users(id),
  username VARCHAR NOT NULL,
  createdAt TIMESTAMP DEFAULT NOW()
);
```

---

## 🔌 Nuevos Endpoints API

### Reacciones

**GET** `/api/tweets/:id/reactions`
- Obtiene todas las reacciones de un tweet

**POST** `/api/tweets/:id/reactions`
- Agrega una reacción a un tweet
- Body: `{ "emoji": "👍" }`
- Toggle automático si ya existe

**DELETE** `/api/reactions/:id`
- Elimina una reacción específica

### Respuestas

**GET** `/api/tweets/:id/replies`
- Obtiene todas las respuestas de un tweet

**POST** `/api/tweets/:id/replies`
- Agrega una respuesta a un tweet
- Body: `{ "text": "Mi mensaje de respuesta" }`

**DELETE** `/api/replies/:id`
- Elimina una respuesta (solo autor y admin)

---

## 📱 Cambios en Flutter

### Nuevos Modelos
- `lib/models/reaction.dart` - Modelo de reacción
- `lib/models/reply.dart` - Modelo de respuesta

### Nuevos Widgets
- `lib/widgets/reactions_widget.dart` - Interfaz de reacciones
- `lib/widgets/replies_widget.dart` - Interfaz de respuestas

### Actualizaciones
- `lib/models/tweet.dart` - Ahora incluye listas de reacciones y replies
- `lib/repositories/tweet_repository.dart` - Interfaz extendida con nuevos métodos
- `lib/services/tweet_service.dart` - Implementación de llamadas API
- `lib/screens/home_screen.dart` - Integración de widgets

---

## 🎨 UI/UX

### Reacciones
```
👍❤️😂😢🔥🎉  <- Botones para agregar reacción
[👍 5] [❤️ 3] [🔥 2]  <- Reacciones existentes (clickeables)
```

### Respuestas
```
3 respuestas ▼  <- Botón para expandir/colapsar

[Campo de respuesta] [Enviar]  <- Siempre visible

Respuestas expandidas:
┌─ @usuario1: Mi respuesta aquí    [×]
├─ @usuario2: Otra respuesta       [×]
└─ @usuario3: Más comentarios      [×]
```

---

## 🛠️ Instalación y Deploy

### Backend
```bash
npm install
npm start
```

La base de datos se sincronizará automáticamente con Sequelize.

### Frontend
```bash
flutter pub get
flutter run
```

---

## 🔐 Permisos

- **Reacciones**: Cualquier usuario autenticado puede reaccionar
- **Respuestas**: Cualquier usuario autenticado puede responder
- **Eliminar Reacción**: Solo el autor de la reacción
- **Eliminar Respuesta**: Solo el autor o admin
- **Admin**: Puede eliminar cualquier respuesta

---

## 🧪 Testing

### Endpoints a Probar

1. **Agregar Reacción**
   ```bash
   curl -X POST http://localhost:3000/api/tweets/1/reactions \
     -H "Authorization: Bearer TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"emoji":"👍"}'
   ```

2. **Obtener Reacciones**
   ```bash
   curl http://localhost:3000/api/tweets/1/reactions
   ```

3. **Agregar Respuesta**
   ```bash
   curl -X POST http://localhost:3000/api/tweets/1/replies \
     -H "Authorization: Bearer TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"text":"¡Excelente moto!"}'
   ```

4. **Obtener Respuestas**
   ```bash
   curl http://localhost:3000/api/tweets/1/replies
   ```

---

## 📝 Notas Importantes

- Las reacciones se cargan automáticamente al abrir la app
- Las respuestas también se cargan junto con los tweets
- El toggle de reacciones es instantáneo en la UI
- Las respuestas no tienen límite de caracteres (recomendado máx 500 caracteres)
- Todos los cambios se sincronizan en tiempo real

---

## 🚀 Próximos Steps (Opcional)

- [ ] Agregar notificaciones cuando alguien reacciona/responde
- [ ] Editar respuestas (en lugar de solo eliminar)
- [ ] Respuestas anidadas (responder a una respuesta)
- [ ] Búsqueda y filtrado por reacciones
- [ ] Analytics de reacciones más populares

---

**Versión**: 2.0.0  
**Fecha**: Mayo 2026  
**Estado**: ✅ Implementado y listo para producción

