export default {
  async check(ctx) {
    try {
      // Simple health check - you can add database connectivity check here
      ctx.body = {
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development',
      };
      ctx.status = 200;
    } catch (error) {
      ctx.body = {
        status: 'error',
        message: error.message,
      };
      ctx.status = 500;
    }
  },
}; 