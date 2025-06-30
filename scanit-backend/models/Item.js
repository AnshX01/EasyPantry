const mongoose = require('mongoose');

const itemSchema = new mongoose.Schema({
  name: { type: String, required: true },
  quantity: { type: Number, required: true },
  expiryDate: { type: Date, required: true },
  dateAdded: {
    type: Date,
    default: Date.now
  },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  status: { type: String, enum: ['active', 'used', 'wasted'], default: 'active' },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Item', itemSchema);
