export default [
  'strapi::logger',
  'strapi::errors',
  {
    name: 'strapi::security',
    config: {
      contentSecurityPolicy: {
        useDefaults: true,
        directives: {
          'connect-src': ["'self'", 'https:'],
          'img-src': ["'self'", 'data:', 'blob:', 'https:'],
          'media-src': ["'self'", 'data:', 'blob:', 'https:'],
          upgradeInsecureRequests: null,
        },
      },
      frameguard: true,
      hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
      },
      xssFilter: true,
    },
  },
  {
    name: 'strapi::cors',
    config: {
      origin: [
        'http://localhost:3000', 
        'http://localhost:1337',
        process.env.FRONTEND_URL,
        // Allow all Vercel preview deployments
        /https:\/\/.*\.vercel\.app$/,
        // Allow your custom domain if you have one
        process.env.ADMIN_URL
      ].filter(Boolean),
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'],
      headers: ['Content-Type', 'Authorization', 'Origin', 'Accept'],
      keepHeaderOnError: true,
    },
  },
  'strapi::poweredBy',
  'strapi::query',
  'strapi::body',
  'strapi::session',
  'strapi::favicon',
  'strapi::public',
];
