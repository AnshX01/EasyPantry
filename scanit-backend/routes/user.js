const express = require("express");
const router = express.Router();
const User = require("../models/User");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");

const JWT_SECRET = process.env.JWT_SECRET;

const authMiddleware = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer "))
    return res.status(401).json({ error: "Unauthorized" });

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ error: "Invalid token" });
  }
};

router.get("/profile", authMiddleware, async (req, res) => {
  const user = await User.findById(req.user.id).select("name email");
  if (!user) return res.status(404).json({ error: "User not found" });

  res.json({ name: user.name, email: user.email });
});

router.put("/profile", authMiddleware, async (req, res) => {
  const { name, email, password } = req.body;
  const user = await User.findById(req.user.id);
  if (!user) return res.status(404).json({ error: "User not found" });

  if (name) user.name = name;
  if (email) user.email = email;
  if (password) {
    const hashed = await bcrypt.hash(password, 10);
    user.passwordHash = hashed;
  }

  await user.save();
  res.json({ message: "Profile updated" });
});

router.put("/change-password", authMiddleware, async (req, res) => {
  const { oldPassword, newPassword } = req.body;
  const user = await User.findById(req.user.id);

  if (!user) return res.status(404).json({ error: "User not found" });

  const isMatch = await bcrypt.compare(oldPassword, user.passwordHash);
  if (!isMatch) return res.status(400).json({ error: "Old password is incorrect" });

  const hashed = await bcrypt.hash(newPassword, 10);
  user.passwordHash = hashed;
  await user.save();

  res.json({ message: "Password updated successfully" });
});

module.exports = router;
