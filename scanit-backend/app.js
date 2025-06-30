const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json());

mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log("MongoDB connected"))
  .catch(err => console.error("MongoDB error:", err));

app.use("/api/stats", require("./routes/stats"));
app.use("/api/auth", require("./routes/auth"));
app.use("/api/items", require("./routes/items"));
app.use("/api/scan", require("./routes/scan"));
app.use("/api/recipes", require("./routes/recipes"));
app.use('/api/grocery', require('./routes/grocery'));


app.listen(3000, () => console.log("Server running on port 3000"));
