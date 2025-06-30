const express = require("express");
const router = express.Router();
const Item = require("../models/Item");
const jwt = require("jsonwebtoken");
const mongoose = require("mongoose");

const JWT_SECRET = process.env.JWT_SECRET;

function authenticateToken(req, res, next) {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];
  if (!token) return res.sendStatus(401);

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
}

router.get("/weekly", authenticateToken, async (req, res) => {
  try {

    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
    console.log("Filtering for userId:", req.user.id);
    console.log("One week ago is:", oneWeekAgo.toISOString());

    const stats = await Item.aggregate([
      {
        $match: {
          userId: new mongoose.Types.ObjectId(req.user.id),
          dateAdded: { $gte: oneWeekAgo },
        },
      },
      {
        $group: {
          _id: "$status",
          count: { $sum: 1 },
        },
      },
    ]);

    console.log("Aggregation result:", stats);

    const formatted = { active: 0, used: 0, wasted: 0 };
    for (const stat of stats) {
      formatted[stat._id] = stat.count;
    }

    res.json({ success: true, data: formatted });
  } catch (err) {
    console.error("Error fetching weekly stats:", err);
    res.status(500).json({ success: false, message: "Failed to get stats" });
  }
});

router.get("/category-breakdown", authenticateToken, async (req, res) => {
  try {
    const result = await Item.aggregate([
      { $match: { userId: new mongoose.Types.ObjectId(req.user.id) } },
      {
        $group: {
          _id: { name: "$name", status: "$status" },
          count: { $sum: 1 },
        },
      },
    ]);

    const breakdown = {};

    for (const entry of result) {
      const { name, status } = entry._id;
      if (!breakdown[name]) breakdown[name] = { used: 0, wasted: 0 };
      breakdown[name][status] = entry.count;
    }

    res.json({ success: true, data: breakdown });
  } catch (err) {
    console.error("Error in category breakdown:", err);
    res.status(500).json({ success: false, message: "Failed to fetch breakdown" });
  }
});

router.get("/daily-trend", authenticateToken, async (req, res) => {
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6); // 7 days range

  try {
    const result = await Item.aggregate([
      {
        $match: {
          userId: new mongoose.Types.ObjectId(req.user.id),
          dateAdded: { $gte: sevenDaysAgo },
          status: { $in: ["used", "wasted"] },
        },
      },
      {
        $group: {
          _id: {
            date: { $dateToString: { format: "%Y-%m-%d", date: "$dateAdded" } },
            status: "$status",
          },
          count: { $sum: 1 },
        },
      },
    ]);

    const dailyData = {};
    for (const entry of result) {
      const { date, status } = entry._id;
      if (!dailyData[date]) dailyData[date] = { used: 0, wasted: 0 };
      dailyData[date][status] = entry.count;
    }

    res.json({ success: true, data: dailyData });
  } catch (err) {
    console.error("Error in daily trend:", err);
    res.status(500).json({ success: false, message: "Failed to fetch daily trend" });
  }
});

router.get("/details", authenticateToken, async (req, res) => {
  const userId = new mongoose.Types.ObjectId(req.user.id);
  const now = new Date();
  const threeDaysFromNow = new Date(now);
  threeDaysFromNow.setDate(now.getDate() + 3);

  try {
    const usedCount = await Item.countDocuments({ userId, status: "used" });
    const wastedCount = await Item.countDocuments({ userId, status: "wasted" });

    const wastePercentage = usedCount + wastedCount === 0
      ? 0
      : (wastedCount / (usedCount + wastedCount)) * 100;

    const nearExpiryCount = await Item.countDocuments({
      userId,
      status: "active",
      expiryDate: { $lte: threeDaysFromNow, $gte: now }
    });

    const mostWastedAgg = await Item.aggregate([
      { $match: { userId, status: "wasted" } },
      { $group: { _id: "$name", count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 3 }
    ]);

    const mostWasted = mostWastedAgg.map(item => item._id);

    res.json({
      success: true,
      data: {
        wastePercentage: parseFloat(wastePercentage.toFixed(1)),
        nearExpiryCount,
        mostWasted
      }
    });
  } catch (err) {
    console.error("Error fetching detailed stats:", err);
    res.status(500).json({ success: false, message: "Failed to fetch detailed stats" });
  }
});


module.exports = router;
