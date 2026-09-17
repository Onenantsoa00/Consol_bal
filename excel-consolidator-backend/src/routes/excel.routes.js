const express = require("express");
const multer = require("multer");
const path = require("path");
const excelController = require("../controllers/excel.controller");

const router = express.Router();

// ✅ Stockage EN MÉMOIRE : plus aucun fichier temporaire, plus aucun ENOENT possible
const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  const allowed = [
    "application/vnd.ms-excel",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "application/octet-stream",
  ];
  const ext = path.extname(file.originalname).toLowerCase();
  if (
    allowed.includes(file.mimetype) ||
    [".xls", ".xlsx", ".csv"].includes(ext)
  ) {
    cb(null, true);
  } else {
    cb(
      new Error("Format de fichier non supporté. Utilisez .xlsx, .xls ou .csv"),
      false,
    );
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 20 * 1024 * 1024 }, // 20 Mo par fichier
});

router.post(
  "/consolidate",
  upload.array("files", 30),
  excelController.consolidate,
);
router.post("/export", excelController.exportExcel);

module.exports = router;
