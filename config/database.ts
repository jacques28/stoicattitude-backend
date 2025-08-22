export default ({ env }) => {
  const client = env('DATABASE_CLIENT', 'postgres');

  if (client === 'sqlite') {
    return {
      connection: {
        client: 'sqlite',
        connection: {
          filename: env('DATABASE_FILENAME', '.tmp/data.db'),
        },
        useNullAsDefault: true,
      },
    };
  }

  // PostgreSQL configuration for production
  return {
    connection: {
      client: 'postgres',
      connection: {
        host: env('DATABASE_HOST', 'localhost'),
        port: env.int('DATABASE_PORT', 5432),
        database: env('DATABASE_NAME', 'strapi_local'),
        user: env('DATABASE_USERNAME', 'strapidev'),
        password: env('DATABASE_PASSWORD'),
        ssl: env.bool('DATABASE_SSL', false) ? {
          rejectUnauthorized: env.bool('DATABASE_SSL_REJECT_UNAUTHORIZED', false),
        } : false,
        schema: env('DATABASE_SCHEMA', 'public'),
      },
      pool: { 
        min: env.int('DATABASE_POOL_MIN', 2), 
        max: env.int('DATABASE_POOL_MAX', 10),
        acquireTimeoutMillis: env.int('DATABASE_CONNECTION_TIMEOUT', 60000),
        idleTimeoutMillis: env.int('DATABASE_IDLE_TIMEOUT', 30000),
      },
      debug: env.bool('DATABASE_DEBUG', false),
    },
  };
};
