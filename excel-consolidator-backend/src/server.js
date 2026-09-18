const express = require("express");
const cors = require("cors");
const excelRoutes = require("./routes/excel.routes");

const app = express();

const PORT = process.env.PORT || 3000;

// ============================================================
// MIDDLEWARES
// ============================================================

app.use(cors());

app.use(
  express.json({
    limit: "50mb",
  }),
);

app.use(
  express.urlencoded({
    extended: true,
    limit: "50mb",
  }),
);

// ============================================================
// ROUTES
// ============================================================

app.use("/api/excel", excelRoutes);

// ============================================================
// ROUTE PRINCIPALE
// ============================================================

app.get("/", (req, res) => {
  res.json({
    message: "API Excel Consolidator opérationnelle ✅",
  });
});

// ============================================================
// ROUTE DE SANTE
// ============================================================

app.get("/api/health", (req, res) => {
  res.status(200).json({
    status: "ok",
    message: "Backend opérationnel",
  });
});

// ============================================================
// GESTION DES ERREURS
// ============================================================

app.use((err, req, res, next) => {
  console.error("Erreur:", err);

  res.status(500).json({
    error: err.message || "Une erreur interne est survenue.",
  });
});

// ============================================================
// DEMARRAGE DU SERVEUR
// ============================================================

app.listen(PORT, () => {
  console.log(`🚀 Serveur démarré sur http://localhost:${PORT}`);
});
