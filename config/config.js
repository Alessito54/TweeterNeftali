require('dotenv').config();
const fs = require('fs');
const path = require('path');

// Base SSL options for Aiven
const sslOptions = {
  require: true,
  // By default do not reject unauthorized to be compatible with environments
  rejectUnauthorized: false
};

// Prefer AIVEN_CA env var (PEM content). Otherwise, fall back to a local ca.pem file path.
if (process.env.AIVEN_CA && process.env.AIVEN_CA.length > 0) {
  sslOptions.rejectUnauthorized = true;
  sslOptions.ca = process.env.AIVEN_CA;
  console.log('Using Aiven CA certificate from AIVEN_CA env var');
} else if (process.env.AIVEN_CA_B64 && process.env.AIVEN_CA_B64.length > 0) {
  try {
    sslOptions.rejectUnauthorized = true;
    sslOptions.ca = Buffer.from(process.env.AIVEN_CA_B64, 'base64').toString('utf8');
    console.log('Using Aiven CA certificate from AIVEN_CA_B64 env var');
  } catch (err) {
    console.warn('Could not decode AIVEN_CA_B64:', err.message);
  }
} else {
  const caPath = process.env.AIVEN_CA_PATH || path.resolve(process.cwd(), 'ca.pem');
  if (fs.existsSync(caPath)) {
    try {
      const ca = fs.readFileSync(caPath).toString();
      sslOptions.rejectUnauthorized = true;
      sslOptions.ca = ca;
      console.log('Using Aiven CA certificate from', caPath);
    } catch (err) {
      console.warn('Could not read CA file at', caPath, err.message);
    }
  }
}


// Allow a temporary insecure mode for testing (do NOT use in production)
if (process.env.AIVEN_ALLOW_INSECURE === 'true') {
  console.warn('AIVEN_ALLOW_INSECURE=true set — SSL certificate verification DISABLED (insecure)');
  sslOptions.rejectUnauthorized = false;
  delete sslOptions.ca;
  // Also disable Node-level TLS verification for environments where driver checks happen
  try {
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
    console.warn('NODE_TLS_REJECT_UNAUTHORIZED set to 0 (insecure)');
  } catch (e) {
    // ignore
  }
}
// Support running locally with SQLite for development (no Postgres required).
// To enable SQLite locally, set USE_SQLITE=true in your .env. You can also
// set SQLITE_FILE to change the sqlite file path (defaults to ./neftali.sqlite).
let dbConfig;
if (process.env.USE_SQLITE === 'true' || (process.env.DATABASE_URL && process.env.DATABASE_URL.startsWith('sqlite'))) {
  const storageFile = process.env.SQLITE_FILE || 'neftali.sqlite';
  console.log('Using SQLite for development. File:', storageFile);
  dbConfig = {
    use_env_variable: 'DATABASE_URL',
    dialect: 'sqlite',
    storage: storageFile,
    logging: false
  };
} else {
  dbConfig = {
    use_env_variable: 'DATABASE_URL',
    dialect: 'postgres',
    dialectOptions: {
      ssl: sslOptions
    },
    logging: false
  };
}

module.exports = {
  development: dbConfig,
  test: dbConfig,
  production: dbConfig
};
