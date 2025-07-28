import { MongoClient } from 'mongodb';

export default {
  async connectToMongo() {
    const client = new MongoClient(process.env.MONGODB_URI);
    await client.connect();
    return client.db();
  },

  async findUser(email: string) {
    const db = await this.connectToMongo();
    return await db.collection('users').findOne({ email });
  },

  async createUser(userData: any) {
    const db = await this.connectToMongo();
    return await db.collection('users').insertOne(userData);
  },

  async updateUser(email: string, userData: any) {
    const db = await this.connectToMongo();
    return await db.collection('users').updateOne(
      { email },
      { $set: userData }
    );
  },
}; 