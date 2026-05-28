require('dotenv').config();
const db = require('./models');

/**
 * Script para resetear la tabla de reacciones con el constraint correcto
 * Ejecutar: AIVEN_ALLOW_INSECURE=true node reset-reactions-table.js
 */

async function resetReactionsTable() {
  try {
    console.log('Conectando a la base de datos...');
    await db.sequelize.authenticate();
    console.log('✓ Conectado a la BD');

    // Eliminar la tabla si existe
    console.log('Eliminando tabla reactions (si existe)...');
    await db.sequelize.query('DROP TABLE IF EXISTS reactions CASCADE');
    console.log('✓ Tabla eliminada');

    // Recrear la tabla con el constraint correcto
    console.log('Creando tabla reactions con constraint correcto...');
    await db.sequelize.query(`
      CREATE TABLE reactions (
        id SERIAL PRIMARY KEY,
        emoji VARCHAR(10) NOT NULL,
        "tweetId" INTEGER NOT NULL REFERENCES tweets(id) ON DELETE CASCADE,
        "userId" INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        "createdAt" TIMESTAMP DEFAULT NOW(),
        UNIQUE("tweetId", "userId")
      )
    `);
    console.log('✓ Tabla reactions creada con UNIQUE("tweetId", "userId")');

    console.log('✓ ¡Tabla reseteada correctamente!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

resetReactionsTable();
