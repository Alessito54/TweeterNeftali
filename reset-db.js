require('dotenv').config();
const db = require('./models');

const resetDB = async () => {
  try {
    console.log('Dropping tables...');
    await db.sequelize.drop();
    
    console.log('Syncing database...');
    await db.sequelize.sync({ force: true });
    
    console.log('Database reset successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error resetting database:', error);
    process.exit(1);
  }
};

resetDB();
