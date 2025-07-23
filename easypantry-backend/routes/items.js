// routes/items.js
const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const Item = require('../models/Item');

const JWT_SECRET = process.env.JWT_SECRET;

function authenticateToken(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'Access Denied' });

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ message: 'Invalid token' });
    req.user = user;
    next();
  });
}

router.post('/add', authenticateToken, async (req, res) => {
  const { name, quantity, expiryDate } = req.body;
  const userId = req.user.id;

  const newItem = new Item({ name, quantity, expiryDate, userId });
  await newItem.save();
  res.status(201).json({ success: true, item: newItem , message: 'Item added successfully' });
});

router.get('/', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const items = await Item.find({ userId, status: 'active' }).sort({ expiryDate: 1 });
  res.json(items);
});

router.put('/update/:id', authenticateToken, async (req, res) => {
    const { id } = req.params;
    const { quantity, expiryDate } = req.body;

    try {
      const item = await Item.findOneAndUpdate(
        { _id: id, userId: req.user.id },
        { quantity, expiryDate },
        { new: true }
      );
      if (!item) return res.status(404).json({ success: false, message: "Item not found" });
      res.json({ success: true, item });
    } catch (err) {
      res.status(500).json({ success: false, message: "Update failed" });
    }
  });


router.post('/use/:id', authenticateToken, async (req, res) => {
  try {
    const itemId = req.params.id;
    const item = await Item.findOneAndUpdate(
      { _id: itemId, userId: req.user.id },
      { status: 'used' },
      { new: true }
    );
    if (!item) return res.status(404).json({ message: "Item not found" });
    res.json({ success: true, message: "Item marked as used", item });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

router.post('/waste/:id', authenticateToken, async (req, res) => {
  try {
    const itemId = req.params.id;
    const item = await Item.findOneAndUpdate(
      { _id: itemId, userId: req.user.id },
      { status: 'wasted' },
      { new: true }
    );
    if (!item) return res.status(404).json({ message: "Item not found" });
    res.json({ success: true, message: "Item marked as wasted", item });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

router.get('/used', authenticateToken, async (req, res) => {
  try {
    const items = await Item.find({ userId: req.user.id, status: 'used' }).sort({ expiryDate: 1 });
    res.json(items);
  } catch (err) {
    console.error("❌ Error fetching used items:", err);
    res.status(500).json({ message: 'Failed to fetch used items' });
  }
});

router.get('/wasted', authenticateToken, async (req, res) => {
  try {
    const items = await Item.find({ userId: req.user.id, status: 'wasted' }).sort({ expiryDate: 1 });
    res.json(items);
  } catch (err) {
    console.error("❌ Error fetching wasted items:", err);
    res.status(500).json({ message: 'Failed to fetch wasted items' });
  }
});


router.post('/auto-waste', authenticateToken, async (req, res) => {
  try {
    const { itemId } = req.body;
    const userId = req.user.id;

    const item = await Item.findOneAndDelete({ _id: itemId, user: userId });

    if (!item) {
      return res.status(404).json({ success: false, message: "Item not found" });
    }

    const wasted = new Wasted({
      name: item.name,
      quantity: item.quantity,
      expiryDate: item.expiryDate,
      dateWasted: new Date(),
      user: userId,
    });

    await wasted.save();

    return res.json({ success: true, message: "Item marked as wasted automatically" });
  } catch (err) {
    return res.status(500).json({ success: false, message: "Error processing item" });
  }
});


module.exports = router;
