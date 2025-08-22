export default ({ env }) => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('PORT', 1337),
  app: {
    keys: env.array('APP_KEYS'),
  },
  // URL configuration for production
  url: env('PUBLIC_URL', 'http://localhost:1337'),
  proxy: env.bool('BEHIND_PROXY', false),
  cron: {
    enabled: env.bool('CRON_ENABLED', false),
  },
  // Admin panel settings
  admin: {
    autoOpen: false,
  },
  // CORS configuration for frontend communication
  cors: {
    enabled: true,
    origin: [
      env('FRONTEND_URL', 'http://localhost:3000'),
      'https://stoicattitude.com',
      'https://www.stoicattitude.com',
      'https://stoic-attitude.vercel.app', // Add your Vercel domain if different
    ],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
    headers: [
      'Content-Type',
      'Authorization',
      'X-Frame-Options',
      'Origin',
      'Accept',
      'X-Requested-With',
    ],
  },
});
