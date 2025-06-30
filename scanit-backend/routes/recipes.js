const express = require('express');
const router = express.Router();
const axios = require('axios');
const Item = require('../models/Item');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;
const SPOONACULAR_API_KEY = process.env.SPOONACULAR_API_KEY;

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.sendStatus(401);

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
}

router.get('/:userId', authenticateToken, async (req, res) => {
  try {
    const userId = req.params.userId;
    const items = await Item.find({ userId, status: 'active' });

    if (!items.length) return res.json({ success: true, recipes: [] });

    const ingredients = items.map(item => item.name).join(',');

    const params = {
      ingredients,
      number: 30,
      ranking: 1,
      ignorePantry: true,
      apiKey: SPOONACULAR_API_KEY,
    };

    const response = await axios.get(
      'https://api.spoonacular.com/recipes/findByIngredients',
      { params }
    );

    res.json({ success: true, recipes: response.data });
  } catch (error) {
    console.error('Error fetching recipes:', error.message);
    res.status(500).json({ success: false, message: 'Failed to fetch recipes' });
  }
});

module.exports = router;
