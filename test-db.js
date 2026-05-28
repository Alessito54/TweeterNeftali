const db = require('./models');

async function test() {
  try {
    await db.sequelize.authenticate();
    console.log('DB OK');
    process.exit(0);
  } catch (err) {
    console.error('DB ERROR', err.message || err);
    process.exit(1);
  }
}

test();
