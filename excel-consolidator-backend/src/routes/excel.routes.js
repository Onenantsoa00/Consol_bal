const express = require("express");
const multer = require("multer");
const path = require("path");
const excelController = require("../controllers/excel.controller");

const router = express.Router();

// Configuration multer : stockage temporaire
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, "../../uploads"));
  },
  filename: (req, file, cb) => {
    const unique = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, `${unique}-${file.originalname}`);
  },
});

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
  limits: { fileSize: 20 * 1024 * 1024 }, // 20 Mo
});

// POST /api/excel/consolidate
router.post(
  "/consolidate",
  upload.array("files", 20),
  excelController.consolidate,
);

// POST /api/excel/export
router.post("/export", excelController.exportExcel);

module.exports = router;
