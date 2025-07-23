const express = require('express');
const router = express.Router();
const GroceryItem = require('../models/GroceryItem');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;

function authenticateToken(req, res, next) {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.sendStatus(401);

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
}

router.get('/', authenticateToken, async (req, res) => {
  const items = await GroceryItem.find({ userId: req.user.id });
  res.json({ success: true, items });
});

router.post('/', authenticateToken, async (req, res) => {
  const { name, quantity = 1, unit = '' } = req.body;

  const existingItem = await GroceryItem.findOne({
    userId: req.user.id,
    name: { $regex: new RegExp(`^${name}$`, 'i') }
  });

  if (existingItem) {
    return res.status(200).json({ success: false, message: 'Item already in grocery list' });
  }

  const newItem = new GroceryItem({ userId: req.user.id, name, quantity, unit });
  await newItem.save();

  res.json({ success: true, item: newItem });
});

router.put('/:id', authenticateToken, async (req, res) => {
  const { name, quantity, unit } = req.body;
  const updated = await GroceryItem.findOneAndUpdate(
    { _id: req.params.id, userId: req.user.id },
    { name, quantity, unit },
    { new: true }
  );
  res.json({ success: true, item: updated });
});



router.delete('/:id', authenticateToken, async (req, res) => {
  await GroceryItem.findOneAndDelete({ _id: req.params.id, userId: req.user.id });
  res.json({ success: true });
});

module.exports = router;
