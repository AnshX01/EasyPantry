const mongoose = require('mongoose');

const bookmarkSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  recipeId: { type: Number, required: true },
  recipeData: { type: Object, required: true },
});

module.exports = mongoose.model('Bookmark', bookmarkSchema);
