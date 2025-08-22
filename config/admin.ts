export default ({ env }) => ({
  auth: {
    secret: env('ADMIN_JWT_SECRET'),
  },
  apiToken: {
    salt: env('API_TOKEN_SALT'),
  },
  transfer: {
    token: {
      salt: env('TRANSFER_TOKEN_SALT'),
    },
  },
  flags: {
    nps: env.bool('FLAG_NPS', true),
    promoteEE: env.bool('FLAG_PROMOTE_EE', true),
  },
  // Admin panel configuration for api.stoicattitude.com
  url: env('ADMIN_URL', '/admin'),
  autoOpen: false,
  watchIgnoreFiles: [
    './app/**',
    './dist/**',
    '.cache/**',
    '.tmp/**',
    '**/*.log',
  ],
  host: env('ADMIN_HOST', 'localhost'),
  port: env.int('ADMIN_PORT', 8000),
  // Security settings for production
  serveAdminPanel: env.bool('SERVE_ADMIN', true),
  forgotPassword: {
    emailTemplate: {
      subject: 'Reset password for <%= user.firstname %> <%= user.lastname %>',
      text: `Hello,
A request has been made to reset the password for the Stoic Attitude Admin account: <%= user.email %>.
If you DID NOT make this request, please ignore this email.
Otherwise, click the link below to reset your password:
<%= url %>
Thanks.`,
      html: `<p>Hello,</p>
<p>A request has been made to reset the password for the <strong>Stoic Attitude Admin</strong> account: <strong><%= user.email %></strong>.</p>
<p>If you <strong>DID NOT</strong> make this request, please ignore this email.</p>
<p>Otherwise, click the link below to reset your password:</p>
<p><%= url %></p>
<p>Thanks.</p>`,
    },
  },
});
