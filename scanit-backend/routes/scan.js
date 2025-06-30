const express = require("express");
const router = express.Router();
const multer = require("multer");
const jwt = require("jsonwebtoken");
const axios = require("axios");
const Item = require("../models/Item");

const Quagga = require('@ericblade/quagga2'); // npm install @ericblade/quagga2
const { createCanvas, loadImage } = require("canvas"); // npm install canvas

const storage = multer.memoryStorage();
const upload = multer({ storage });

const JWT_SECRET = process.env.JWT_SECRET;

// Middleware
function authenticateToken(req, res, next) {
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) return res.status(401).json({ message: "No token provided" });

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ message: "Invalid token" });
    req.user = user;
    next();
  });
}

// POST /api/scan
router.post("/", authenticateToken, upload.single("image"), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: "No image uploaded" });

    console.log("📸 Received image");

    const img = await loadImage(req.file.buffer);
    const canvas = createCanvas(img.width, img.height);
    const ctx = canvas.getContext("2d");
    ctx.drawImage(img, 0, 0);

    const imageData = ctx.getImageData(0, 0, img.width, img.height);

    const result = await Quagga.decodeSingle({
      src: null,
      inputStream: {
        size: 800,
      },
      decoder: {
        readers: ["ean_reader", "ean_13_reader", "upc_reader"],
      },
      locate: true,
      numOfWorkers: 0,
      singleChannel: false,
      ...{ image: imageData }
    });

    if (!result || !result.codeResult) {
      return res.status(400).json({ success: false, message: "Barcode not detected" });
    }

    const barcode = result.codeResult.code;
    console.log("🔍 Decoded barcode:", barcode);

    const productRes = await axios.get(`https://world.openfoodfacts.org/api/v0/product/${barcode}.json`);
    if (productRes.data.status !== 1) {
      return res.status(404).json({ success: false, message: "Product not found" });
    }

    const product = productRes.data.product;
    const userId = req.user.id;

    const newItem = new Item({
      name: product.product_name || "Unnamed Product",
      quantity: 1,
      expiryDate: null,
      userId,
    });

    await newItem.save();
    res.status(201).json({ success: true, message: "Item added", item: newItem });

  } catch (err) {
  console.error("❌ Error in scan route:", err.stack || err);
  res.status(500).json({ success: false, message: "Server error during scan", error: err.message });
  }
});

module.exports = router;
