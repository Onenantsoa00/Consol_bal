const express = require("express");
const cors = require("cors");
const path = require("path");
const excelRoutes = require("./routes/excel.routes");

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors());
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ extended: true, limit: "50mb" }));

// Routes
app.use("/api/excel", excelRoutes);

// Route de santé
app.get("/", (req, res) => {
  res.json({ message: "API Excel Consolidator opérationnelle ✅" });
});

// Gestion des erreurs
app.use((err, req, res, next) => {
  console.error("Erreur:", err.message);
  res.status(500).json({ error: err.message });
});

app.listen(PORT, () => {
  console.log(`🚀 Serveur démarré sur http://localhost:${PORT}`);
});
