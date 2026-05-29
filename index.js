require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const jwt = require('jsonwebtoken');
const bcryptjs = require('bcryptjs');
const path = require('path');
const cloudinary = require('./cloudinary');
const db = require('./models');

const app = express();
const PORT = process.env.PORT || 3000;

// Configurar multer para uploads temporales
const upload = multer({ dest: 'uploads/' });

// Middlewares
app.use(cors());
app.use(express.json());

// Middleware para verificar JWT
const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const token = authHeader.substring(7);
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.id;
    req.username = decoded.username;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

const getUserRole = (user) => (user && user.username === 'admin' ? 'ADMIN' : 'USER');

const seedAdminUser = async () => {
  const adminUser = await db.User.findOne({ where: { username: 'admin' } });

  if (!adminUser) {
    const hashedPassword = await bcryptjs.hash('12345678', 10);
    await db.User.create({
      username: 'admin',
      password: hashedPassword,
      email: 'admin@tweeter.local',
      name: 'Administrador'
    });
    console.log('Admin user created: admin / 12345678');
  }
};

// ==================== AUTH ENDPOINTS ====================

// POST /api/auth/register - Registrar nuevo usuario
app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, password, email } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: 'Usuario y contraseña requeridos' });
    }

    // Verificar si el usuario ya existe
    const existingUser = await db.User.findOne({ where: { username } });
    if (existingUser) {
      return res.status(409).json({ error: 'El usuario ya existe' });
    }

    // Hash password
    const hashedPassword = await bcryptjs.hash(password, 10);

    const user = await db.User.create({
      username,
      password: hashedPassword,
      email: email || `${username}@tweeter.local`,
      name: username
    });

    const token = jwt.sign(
      { id: user.id, username: user.username, role: getUserRole(user) },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        name: user.name,
        role: getUserRole(user)
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error en el registro: ' + error.message });
  }
});

// POST /api/auth/login - Login de usuario
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password required' });
    }

    const user = await db.User.findOne({ where: { username } });
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const isPasswordValid = await bcryptjs.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { id: user.id, username: user.username, role: getUserRole(user) },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(200).json({
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        name: user.name,
        role: getUserRole(user)
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// ==================== TWEETS ENDPOINTS ====================

// GET /api/tweets - Obtener todos los tweets (público)
app.get('/api/tweets', async (req, res) => {
  try {
    const tweets = await db.Tweet.findAll({
      include: [
        {
          model: db.Reaction,
          attributes: ['id', 'emoji', 'userId', 'createdAt'],
          include: [
            {
              model: db.User,
              attributes: ['id', 'username']
            }
          ]
        },
        {
          model: db.Reply,
          attributes: ['id', 'text', 'userId', 'username', 'createdAt'],
          include: [
            {
              model: db.User,
              attributes: ['id', 'username']
            }
          ]
        }
      ],
      order: [['createdAt', 'DESC']]
    });
    res.status(200).json({ tweets });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// POST /api/tweets - Crear nuevo tweet
app.post('/api/tweets', verifyToken, upload.single('imagen'), async (req, res) => {
  try {
    const { text, motoMarca, motoModelo, motoCilindrada } = req.body;

    if (!text) {
      return res.status(400).json({ error: 'El texto del tweet es requerido' });
    }

    let imageUrl = null;

    // Si hay imagen, subirla a Cloudinary
    if (req.file) {
      const result = await cloudinary.uploader.upload(req.file.path, {
        folder: 'tweets-app',
        resource_type: 'auto'
      });
      imageUrl = result.secure_url;

      // Eliminar archivo temporal
      const fs = require('fs');
      fs.unlinkSync(req.file.path);
    }

    const user = await db.User.findByPk(req.userId);
    
    const tweet = await db.Tweet.create({
      text,
      imageUrl,
      username: user.username,
      userId: req.userId,
      motoMarca: motoMarca || null,
      motoModelo: motoModelo || null,
      motoCilindrada: motoCilindrada ? parseInt(motoCilindrada) : null
    });

    res.status(201).json(tweet);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// DELETE /api/tweets/:id - Eliminar tweet
app.delete('/api/tweets/:id', verifyToken, async (req, res) => {
  try {
    const tweet = await db.Tweet.findByPk(req.params.id);

    if (!tweet) {
      return res.status(404).json({ error: 'Tweet no encontrado' });
    }

    const currentUser = await db.User.findByPk(req.userId);
    const isAdmin = currentUser && currentUser.username === 'admin';

    // Solo el autor o admin pueden eliminar
    if (tweet.userId !== req.userId && !isAdmin) {
      return res.status(403).json({ error: 'No tienes permiso para eliminar este tweet' });
    }

    await tweet.destroy();
    res.status(200).json({ message: 'Tweet eliminado' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// ==================== REACTIONS ENDPOINTS ====================

// GET /api/tweets/:id/reactions - Obtener reacciones de un tweet
app.get('/api/tweets/:id/reactions', async (req, res) => {
  try {
    const reactions = await db.Reaction.findAll({
      where: { tweetId: req.params.id },
      include: [
        {
          model: db.User,
          attributes: ['id', 'username']
        }
      ]
    });
    res.status(200).json({ reactions });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// POST /api/tweets/:id/reactions - Agregar reacción a un tweet
app.post('/api/tweets/:id/reactions', verifyToken, async (req, res) => {
  try {
    const { emoji } = req.body;

    if (!emoji) {
      return res.status(400).json({ error: 'El emoji es requerido' });
    }

    const tweet = await db.Tweet.findByPk(req.params.id);
    if (!tweet) {
      return res.status(404).json({ error: 'Tweet no encontrado' });
    }

    // Verificar si el usuario ya reaccionó a este tweet
    const existingReaction = await db.Reaction.findOne({
      where: {
        tweetId: req.params.id,
        userId: req.userId
      }
    });

    if (existingReaction) {
      // Si el emoji es el mismo, eliminar (toggle)
      if (existingReaction.emoji === emoji) {
        await existingReaction.destroy();
        
        // Retornar TODAS las reacciones actualizadas
        const allReactions = await db.Reaction.findAll({
          where: { tweetId: req.params.id },
          include: [{ model: db.User, attributes: ['id', 'username'] }]
        });
        
        return res.status(200).json({ 
          message: 'Reacción eliminada', 
          reactions: allReactions
        });
      } else {
        // Si es diferente, actualizar el emoji
        existingReaction.emoji = emoji;
        await existingReaction.save();
      }
    } else {
      // Crear nueva reacción
      await db.Reaction.create({
        emoji,
        tweetId: req.params.id,
        userId: req.userId
      });
    }

    // Retornar TODAS las reacciones actualizadas
    const allReactions = await db.Reaction.findAll({
      where: { tweetId: req.params.id },
      include: [{ model: db.User, attributes: ['id', 'username'] }]
    });

    res.status(201).json({ 
      message: 'Reacción guardada', 
      reactions: allReactions 
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// DELETE /api/reactions/:id - Eliminar reacción
app.delete('/api/reactions/:id', verifyToken, async (req, res) => {
  try {
    const reaction = await db.Reaction.findByPk(req.params.id);

    if (!reaction) {
      return res.status(404).json({ error: 'Reacción no encontrada' });
    }

    if (reaction.userId !== req.userId) {
      return res.status(403).json({ error: 'No tienes permiso para eliminar esta reacción' });
    }

    await reaction.destroy();
    res.status(200).json({ message: 'Reacción eliminada' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// ==================== REPLIES ENDPOINTS ====================

// GET /api/tweets/:id/replies - Obtener respuestas de un tweet
app.get('/api/tweets/:id/replies', async (req, res) => {
  try {
    const replies = await db.Reply.findAll({
      where: { tweetId: req.params.id },
      include: [
        {
          model: db.User,
          attributes: ['id', 'username']
        }
      ],
      order: [['createdAt', 'ASC']]
    });
    res.status(200).json({ replies });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// POST /api/tweets/:id/replies - Crear respuesta a un tweet
app.post('/api/tweets/:id/replies', verifyToken, async (req, res) => {
  try {
    const { text } = req.body;

    if (!text) {
      return res.status(400).json({ error: 'El texto de la respuesta es requerido' });
    }

    const tweet = await db.Tweet.findByPk(req.params.id);
    if (!tweet) {
      return res.status(404).json({ error: 'Tweet no encontrado' });
    }

    const user = await db.User.findByPk(req.userId);

    const reply = await db.Reply.create({
      text,
      tweetId: req.params.id,
      userId: req.userId,
      username: user.username
    });

    const replyWithUser = await db.Reply.findByPk(reply.id, {
      include: [
        {
          model: db.User,
          attributes: ['id', 'username']
        }
      ]
    });

    res.status(201).json(replyWithUser);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// DELETE /api/replies/:id - Eliminar respuesta
app.delete('/api/replies/:id', verifyToken, async (req, res) => {
  try {
    const reply = await db.Reply.findByPk(req.params.id);

    if (!reply) {
      return res.status(404).json({ error: 'Respuesta no encontrada' });
    }

    const currentUser = await db.User.findByPk(req.userId);
    const isAdmin = currentUser && currentUser.username === 'admin';

    // Solo el autor o admin pueden eliminar
    if (reply.userId !== req.userId && !isAdmin) {
      return res.status(403).json({ error: 'No tienes permiso para eliminar esta respuesta' });
    }

    await reply.destroy();
    res.status(200).json({ message: 'Respuesta eliminada' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// ==================== MOTOS ENDPOINTS ====================

// GET /api/motos - Obtener todas las motos
app.get('/api/motos', verifyToken, async (req, res) => {
  try {
    const motos = await db.Moto.findAll({ where: { user_id: req.userId } });
    res.status(200).json({ motos });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// GET /api/motos/:id - Obtener una moto específica
app.get('/api/motos/:id', verifyToken, async (req, res) => {
  try {
    const moto = await db.Moto.findOne({
      where: { id: req.params.id, user_id: req.userId }
    });

    if (!moto) {
      return res.status(404).json({ error: 'Moto no encontrada' });
    }

    res.status(200).json(moto);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// POST /api/motos - Crear nueva moto con imagen
app.post('/api/motos', verifyToken, upload.single('imagen'), async (req, res) => {
  try {
    const { marca, modelo, cilindrada } = req.body;

    if (!marca || !modelo || !cilindrada) {
      return res.status(400).json({ error: 'Marca, modelo y cilindrada requeridos' });
    }

    let imagenUrl = null;

    // Si hay imagen, subirla a Cloudinary
    if (req.file) {
      const result = await cloudinary.uploader.upload(req.file.path, {
        folder: 'motos-app',
        resource_type: 'auto'
      });
      imagenUrl = result.secure_url;

      // Eliminar archivo temporal
      const fs = require('fs');
      fs.unlinkSync(req.file.path);
    }

    const moto = await db.Moto.create({
      marca,
      modelo,
      cilindrada: parseInt(cilindrada),
      imagen_url: imagenUrl,
      user_id: req.userId
    });

    res.status(201).json(moto);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// PUT /api/motos/:id - Actualizar moto
app.put('/api/motos/:id', verifyToken, upload.single('imagen'), async (req, res) => {
  try {
    const moto = await db.Moto.findOne({
      where: { id: req.params.id, user_id: req.userId }
    });

    if (!moto) {
      return res.status(404).json({ error: 'Moto no encontrada' });
    }

    const { marca, modelo, cilindrada } = req.body;

    // Actualizar campos
    if (marca) moto.marca = marca;
    if (modelo) moto.modelo = modelo;
    if (cilindrada) moto.cilindrada = parseInt(cilindrada);

    // Si hay nueva imagen
    if (req.file) {
      const result = await cloudinary.uploader.upload(req.file.path, {
        folder: 'motos-app',
        resource_type: 'auto'
      });
      moto.imagen_url = result.secure_url;

      // Eliminar archivo temporal
      const fs = require('fs');
      fs.unlinkSync(req.file.path);
    }

    await moto.save();
    res.status(200).json(moto);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// DELETE /api/motos/:id - Eliminar moto
app.delete('/api/motos/:id', verifyToken, async (req, res) => {
  try {
    const moto = await db.Moto.findOne({
      where: { id: req.params.id, user_id: req.userId }
    });

    if (!moto) {
      return res.status(404).json({ error: 'Moto no encontrada' });
    }

    await moto.destroy();
    res.status(200).json({ message: 'Moto eliminada' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'API is running' });
});

// Root: página informativa simple para cuando no hay frontend desplegado
app.get('/', (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(`
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width,initial-scale=1" />
        <title>AnimeNexus - API</title>
        <style>body{font-family:system-ui,-apple-system,Segoe UI,Roboto,'Helvetica Neue',Arial;padding:24px;color:#222}a{color:#0b5fff}</style>
      </head>
      <body>
        <h1>AnimeNexus</h1>
        <p>Esta URL corresponde al servidor backend de AnimeNexus. Si esperabas ver la aplicación web, despliega el frontend o configura un servicio estático.</p>
        <ul>
          <li><a href="/api/health">Comprobar estado de la API</a></li>
          <li><a href="/api/tweets">Listar tweets (API)</a></li>
        </ul>
        <p>Si quieres que la raíz sirva la app web, puedo ayudarte a desplegar el frontend de AnimeNexus en Render o a servir los archivos estáticos desde aquí.</p>
      </body>
    </html>
  `);
});

// Sincronizar BD e iniciar servidor
db.sequelize.sync().then(async () => {
  await seedAdminUser();
  app.listen(PORT, () => {
    console.log(`
╔════════════════════════════════════════════════════════╗
║      ✨  API DE ANIMENEXUS - EJECUTÁNDOSE             ║
╠════════════════════════════════════════════════════════╣
║  URL: http://localhost:${PORT}                             ║
║                                                        ║
║  📝 Credenciales de prueba:                            ║
║     • Username: admin                                  ║
║     • Password: 12345678                                ║
║                                                        ║
║  🔗 Endpoints:                                          ║
║     • POST   /api/auth/register - Registrar            ║
║     • POST   /api/auth/login - Login                   ║
║     • GET    /api/tweets - Ver publicaciones           ║
║     • POST   /api/tweets - Crear publicación           ║
║     • PUT    /api/tweets/:id - Editar publicación      ║
║     • DELETE /api/tweets/:id - Eliminar publicación    ║
║     • GET    /api/health - Verificar estado            ║
║                                                        ║
║  Base de datos: ${process.env.DATABASE_URL.split('@')[1] || 'postgresql'}
║  📸 Cloudinary: ${process.env.CLOUDINARY_CLOUD_NAME}                     ║
╚════════════════════════════════════════════════════════╝
    `);
  });
}).catch(err => {
  console.error('Error sincronizando BD:', err);
  process.exit(1);
});
