export default {
  async getUser(ctx) {
    try {
      const { email } = ctx.params;
      const mongoAuthService = strapi.service('api::mongo-auth.mongo-auth');
      
      const user = await mongoAuthService.findUser(email);
      
      if (!user) {
        return ctx.notFound('User not found in MongoDB');
      }

      ctx.body = {
        success: true,
        user: {
          id: user._id,
          email: user.email,
          // Add other safe fields you want to expose
        },
      };
    } catch (error) {
      ctx.badRequest('Error fetching user from MongoDB', { error: error.message });
    }
  },

  async syncUser(ctx) {
    try {
      const { email, userData } = ctx.request.body;
      const mongoAuthService = strapi.service('api::mongo-auth.mongo-auth');
      
      // Check if user exists in MongoDB
      const existingUser = await mongoAuthService.findUser(email);
      
      let result;
      if (existingUser) {
        result = await mongoAuthService.updateUser(email, userData);
      } else {
        result = await mongoAuthService.createUser({ email, ...userData });
      }

      ctx.body = {
        success: true,
        message: existingUser ? 'User updated' : 'User created',
        result,
      };
    } catch (error) {
      ctx.badRequest('Error syncing user with MongoDB', { error: error.message });
    }
  },
}; 