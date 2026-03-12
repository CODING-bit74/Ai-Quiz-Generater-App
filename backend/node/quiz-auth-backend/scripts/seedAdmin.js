require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../src/models/user.model');

async function seed() {
    await mongoose.connect(process.env.MONGO_URI);
    const exists = await User.findOne({ email: process.env.ADMIN_SEED_EMAIL });
    if (exists) { console.log('admin exists'); process.exit(0); }
    const pass = await bcrypt.hash(process.env.ADMIN_SEED_PASSWORD, parseInt(process.env.BCRYPT_SALT_ROUNDS || '12', 10));
    await User.create({ email: process.env.ADMIN_SEED_EMAIL, password: pass, roles: ['admin'] });
    console.log('admin created');
    process.exit(0);
}
seed();