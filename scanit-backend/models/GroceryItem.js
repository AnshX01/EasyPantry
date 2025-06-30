const mongoose = require('mongoose');

const GroceryItemSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  name: { type: String, required: true },
  quantity: { type: Number, default: 1 },
  unit: { type: String, default: '' },
  addedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('GroceryItem', GroceryItemSchema);
