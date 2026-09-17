const XLSX = require("xlsx");
const fs = require("fs");

/* =========================================================================
 * UTILITAIRES
 * ========================================================================= */

/**
 * Vérifie qu'une valeur ressemble à un numéro de compte
 */
function isAccountNumber(value) {
  if (value === null || value === undefined) return false;
  const s = String(value).trim();
  if (!s) return false;
  return /^\d{3,10}$/.test(s);
}

/**
 * Convertit une valeur en nombre, ou null si vide
 */
function toNumberOrNull(v) {
  if (v === null || v === undefined) return null;
  const s = String(v).trim();
  if (s === "") return null;
  if (typeof v === "number") return Number.isFinite(v) ? v : null;
  const cleaned = s.replace(/\s/g, "").replace(",", ".");
  const n = parseFloat(cleaned);
  return Number.isFinite(n) ? n : null;
}

/**
 * Vérifie si un compte contient au moins une donnée exploitable.
 * On considère qu'un compte "existe" s'il a au moins une valeur non nulle.
 */
function hasAnyData(acc) {
  return [
    acc.balance_entree_debit,
    acc.balance_entree_credit,
    acc.operation_gestion_debit,
    acc.operation_gestion_credit,
    acc.total_general_debit,
    acc.total_general_credit,
    acc.solde_debit,
    acc.solde_credit,
    acc.operation_fin_gestion_debit,
    acc.operation_fin_gestion_credit,
    acc.balance_sortie_debit,
    acc.balance_sortie_credit,
  ].some((v) => v !== null && v !== undefined && v !== 0);
}

function getClasse(account) {
  return String(account).trim().charAt(0);
}

/**
 * Détecte si une feuille est une vraie balance générale.
 * Critères : la feuille doit contenir une ligne qui commence par "N°COMPTE"
 * ET dont la cellule suivante contient "BALANCE" (insensible à la casse).
 */
function isBalanceSheet(sheet) {
  if (!sheet || !sheet["!ref"]) return false;

  const rows = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: "" });
  const limit = Math.min(rows.length, 20); // on cherche dans les 20 premières lignes

  for (let i = 0; i < limit; i++) {
    const row = rows[i];
    if (!row || row.length === 0) continue;

    const colA = String(row[0] ?? "")
      .trim()
      .toUpperCase();
    if (
      !colA.includes("N°COMPTE") &&
      !colA.includes("N° COMPTE") &&
      !colA.includes("COMPTE")
    ) {
      continue;
    }

    // On cherche "BALANCE" dans l'une des cellules suivantes
    const foundBalance = row.slice(1, 5).some((c) =>
      String(c ?? "")
        .toUpperCase()
        .includes("BALANCE"),
    );

    if (foundBalance) return true;
  }

  return false;
}

/**
 * Extrait les comptes d'une feuille Excel
 */
function extractAccountsFromSheet(sheet) {
  const rows = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: "" });

  // 1. Trouver la ligne d'en-tête qui contient "N°COMPTE" et "BALANCE"
  let headerRowIndex = -1;
  for (let i = 0; i < Math.min(rows.length, 20); i++) {
    const row = rows[i];
    if (!row || row.length === 0) continue;
    const colA = String(row[0] ?? "")
      .trim()
      .toUpperCase();
    if (colA.includes("COMPTE")) {
      const foundBalance = row.slice(1, 5).some((c) =>
        String(c ?? "")
          .toUpperCase()
          .includes("BALANCE"),
      );
      if (foundBalance) {
        headerRowIndex = i;
        break;
      }
    }
  }

  if (headerRowIndex === -1) return [];

  // 2. Chercher la ligne "DEBIT | CREDIT | ..." juste après pour être sûr
  // que les colonnes de données sont bien alignées
  // Dans les 2 formats vus, la ligne suivante (ou 2 lignes après) contient
  // les sous-en-têtes DEBIT/CREDIT. Les données commencent après.
  let dataStartIndex = headerRowIndex + 1;

  // Vérifier s'il y a une ligne DEBIT/CREDIT qui suit immédiatement
  for (
    let i = headerRowIndex + 1;
    i < Math.min(headerRowIndex + 4, rows.length);
    i++
  ) {
    const row = rows[i];
    if (!row) continue;
    const cells = row.map((c) =>
      String(c ?? "")
        .trim()
        .toUpperCase(),
    );
    // La ligne DEBIT/CREDIT contient au moins 3 fois "DEBIT" et "CREDIT"
    const debitCount = cells.filter((c) => c === "DEBIT").length;
    const creditCount = cells.filter((c) => c === "CREDIT").length;
    if (debitCount >= 2 && creditCount >= 2) {
      dataStartIndex = i + 1;
      break;
    }
  }

  // 3. Extraire les comptes
  const accounts = [];
  for (let i = dataStartIndex; i < rows.length; i++) {
    const row = rows[i];
    if (!row || row.length === 0) continue;

    const colA = row[0];
    if (!isAccountNumber(colA)) continue;

    const labelB = String(row[1] ?? "")
      .trim()
      .toLowerCase();
    if (labelB.startsWith("total")) continue;

    const acc = {
      compte: String(colA).trim(),
      classe: getClasse(colA),
      balance_entree_debit: toNumberOrNull(row[1]),
      balance_entree_credit: toNumberOrNull(row[2]),
      operation_gestion_debit: toNumberOrNull(row[3]),
      operation_gestion_credit: toNumberOrNull(row[4]),
      total_general_debit: toNumberOrNull(row[5]),
      total_general_credit: toNumberOrNull(row[6]),
      solde_debit: toNumberOrNull(row[7]),
      solde_credit: toNumberOrNull(row[8]),
      operation_fin_gestion_debit: toNumberOrNull(row[9]),
      operation_fin_gestion_credit: toNumberOrNull(row[10]),
      balance_sortie_debit: toNumberOrNull(row[11]),
      balance_sortie_credit: toNumberOrNull(row[12]),
    };

    // Ignorer les comptes qui n'ont pas de données utiles
    // ⚠️ On regarde UNIQUEMENT la colonne B (balance_entree_debit) et les autres
    // colonnes réelles. Si tout est null, on saute.
    if (!hasAnyData(acc)) continue;

    // ⚠️ FILTRE ANTI-DÉCALAGE : Si balance_entree_debit ressemble à un petit entier
    // (2, 4, 8...) ET que TOUTES les autres colonnes sont vides, c'est probablement
    // la colonne "Aux" déguisée. On rejette.
    const otherCols = [
      acc.balance_entree_credit,
      acc.operation_gestion_debit,
      acc.operation_gestion_credit,
      acc.total_general_debit,
      acc.total_general_credit,
      acc.solde_debit,
      acc.solde_credit,
      acc.operation_fin_gestion_debit,
      acc.operation_fin_gestion_credit,
      acc.balance_sortie_debit,
      acc.balance_sortie_credit,
    ];
    const allOthersEmpty = otherCols.every((v) => v === null || v === 0);
    const firstIsTiny =
      acc.balance_entree_debit !== null &&
      Math.abs(acc.balance_entree_debit) <= 10 &&
      Number.isInteger(acc.balance_entree_debit);

    if (allOthersEmpty && firstIsTiny) {
      // C'est un faux compte (ligne "Aux") → on ignore
      continue;
    }

    accounts.push(acc);
  }

  return accounts;
}

/* =========================================================================
 * FUSION (MERGING)
 * =========================================================================
 * Règle 1 : si le même numéro de compte apparaît dans plusieurs fichiers,
 * on additionne les valeurs correspondantes.
 * - null + null     = null
 * - null + X        = X
 * - X + Y           = X + Y
 * - X + 0           = X
 * ========================================================================= */

const VALUE_KEYS = [
  "balance_entree_debit",
  "balance_entree_credit",
  "operation_gestion_debit",
  "operation_gestion_credit",
  "total_general_debit",
  "total_general_credit",
  "solde_debit",
  "solde_credit",
  "operation_fin_gestion_debit",
  "operation_fin_gestion_credit",
  "balance_sortie_debit",
  "balance_sortie_credit",
];

function mergeField(a, b) {
  const aNull = a === null || a === undefined;
  const bNull = b === null || b === undefined;
  if (aNull && bNull) return null;
  if (aNull) return b;
  if (bNull) return a;
  return a + b;
}

function mergeAccounts(existing, incoming) {
  const merged = {
    compte: existing.compte,
    classe: existing.classe,
  };
  for (const key of VALUE_KEYS) {
    merged[key] = mergeField(existing[key], incoming[key]);
  }
  return merged;
}

/**
 * Fusionne tous les comptes identiques (règle 1).
 * Le résultat est un tableau de comptes uniques avec valeurs additionnées.
 */
function mergeAllAccounts(allAccounts) {
  const map = new Map();
  for (const acc of allAccounts) {
    if (map.has(acc.compte)) {
      map.set(acc.compte, mergeAccounts(map.get(acc.compte), acc));
    } else {
      map.set(acc.compte, { ...acc });
    }
  }
  return Array.from(map.values());
}

/* =========================================================================
 * TOTAUX
 * ========================================================================= */

/**
 * Additionne les valeurs d'un ensemble de comptes.
 * Règle 3 : s'il n'y a aucune donnée pour un champ, il reste null.
 */
function sumAccounts(accounts) {
  const result = {};
  for (const key of VALUE_KEYS) {
    let hasValue = false;
    let sum = 0;
    for (const acc of accounts) {
      const v = acc[key];
      if (v !== null && v !== undefined) {
        hasValue = true;
        sum += v;
      }
    }
    result[key] = hasValue ? sum : null;
  }
  return result;
}

/* =========================================================================
 * CONSOLIDATION
 * =========================================================================
 * Règle 3 : regrouper les comptes par classe et n'ajouter une ligne "Total Cl. X"
 * que si la classe contient au moins un compte avec des données.
 * ========================================================================= */

function consolidateAccounts(rawAccounts) {
  // Règle 1 : fusionner les comptes identiques
  const uniqueAccounts = mergeAllAccounts(rawAccounts);

  // Grouper par classe
  const byClass = {};
  for (const acc of uniqueAccounts) {
    if (!byClass[acc.classe]) byClass[acc.classe] = [];
    byClass[acc.classe].push(acc);
  }

  // Trier les classes numériquement
  const sortedClasses = Object.keys(byClass).sort(
    (a, b) => Number(a) - Number(b),
  );

  const result = [];
  const allForGrandTotal = [];

  for (const c of sortedClasses) {
    // Trier les comptes à l'intérieur de la classe par n° croissant
    const accounts = byClass[c].sort((a, b) =>
      a.compte.localeCompare(b.compte, undefined, { numeric: true }),
    );

    // Règle 3 : ne rien ajouter si la classe ne contient aucun compte
    if (accounts.length === 0) continue;

    for (const acc of accounts) {
      result.push({ type: "account", ...acc });
      allForGrandTotal.push(acc);
    }

    // Ligne Total Cl. X uniquement si au moins un compte
    const classTotal = sumAccounts(accounts);
    result.push({
      type: "total-class",
      compte: `Total Cl. ${c}`,
      classe: c,
      ...classTotal,
    });
  }

  // Ligne TOT. GEN. uniquement s'il y a eu au moins un compte
  if (allForGrandTotal.length > 0) {
    const grandTotal = sumAccounts(allForGrandTotal);
    result.push({
      type: "grand-total",
      compte: "TOT. GEN.",
      classe: "",
      ...grandTotal,
    });
  }

  return {
    rows: result,
    classes: sortedClasses,
  };
}

/* =========================================================================
 * CONTROLLER : /api/excel/consolidate
 * ========================================================================= */

exports.consolidate = async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ error: "Aucun fichier reçu." });
    }

    if (req.files.length > 30) {
      return res.status(400).json({ error: "Maximum 30 fichiers autorisés." });
    }

    const allAccounts = [];
    const fileInfos = [];
    const errors = [];

    for (const file of req.files) {
      try {
        // ✅ Lecture DIRECTEMENT depuis la mémoire (file.buffer)
        // Plus besoin de file.path, plus de fs.unlinkSync, plus d'ENOENT
        const workbook = XLSX.read(file.buffer, { type: "buffer" });

        let fileAccounts = 0;

        for (const sheetName of workbook.SheetNames) {
          const sheet = workbook.Sheets[sheetName];
          if (!sheet || !sheet["!ref"]) continue;

          if (!isBalanceSheet(sheet)) continue;

          const accounts = extractAccountsFromSheet(sheet);
          if (accounts.length > 0) {
            allAccounts.push(...accounts);
            fileAccounts += accounts.length;
          }
        }

        fileInfos.push({
          name: file.originalname,
          accounts: fileAccounts,
        });
      } catch (fileErr) {
        // On n'interrompt pas tout si UN fichier pose problème
        console.error(
          `Erreur sur le fichier ${file.originalname}:`,
          fileErr.message,
        );
        errors.push({
          name: file.originalname,
          message: fileErr.message,
        });
        fileInfos.push({
          name: file.originalname,
          accounts: 0,
          error: fileErr.message,
        });
      }
    }

    if (allAccounts.length === 0) {
      return res.status(400).json({
        error:
          "Aucun compte détecté. Vérifiez que les fichiers contiennent une feuille avec l'en-tête \"N°COMPTE | BALANCE D'ENTREE\".",
        details: errors.length > 0 ? errors : undefined,
      });
    }

    const consolidated = consolidateAccounts(allAccounts);
    const uniqueCount = consolidated.rows.filter(
      (r) => r.type === "account",
    ).length;

    res.json({
      success: true,
      filesProcessed: req.files.length,
      totalAccounts: uniqueCount,
      totalRows: consolidated.rows.length,
      classes: consolidated.classes,
      data: consolidated.rows,
      details: fileInfos,
      errors: errors.length > 0 ? errors : undefined,
    });
  } catch (err) {
    console.error("Erreur globale consolidate:", err);
    res
      .status(500)
      .json({ error: `Erreur lors de la consolidation: ${err.message}` });
  }
};
/* =========================================================================
 * CONTROLLER : /api/excel/export
 * ========================================================================= */

/**
 * Règle 2 : cellule vide si null OU 0.
 * Sinon : format fr-FR avec espace comme séparateur de milliers.
 */
function formatNumber(v) {
  if (v === null || v === undefined || v === "") return "";
  const n = Number(v);
  if (!Number.isFinite(n)) return String(v);
  if (n === 0) return ""; // ✅ 0 → cellule vide
  return n
    .toLocaleString("fr-FR", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })
    .replace(/\u202f|\u00a0/g, " ");
}

exports.exportExcel = (req, res) => {
  try {
    const { data, filename } = req.body;

    if (!Array.isArray(data) || data.length === 0) {
      return res.status(400).json({ error: "Aucune donnée à exporter." });
    }

    const aoa = [];

    // Ligne 1 : Titre
    aoa.push([
      "Consolidation Balance",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
    ]);

    // Ligne 2 : En-têtes niveau 1
    aoa.push([
      "N°COMPTE",
      "BALANCE D'ENTREE",
      "",
      "OPERATION GESTION",
      "",
      "TOTAL GENERAL",
      "",
      "SOLDE",
      "",
      "OPERATION FIN GESTION",
      "",
      "BALANCE DE SORTIE",
      "",
    ]);

    // Ligne 3 : DEBIT / CREDIT
    aoa.push([
      "",
      "DEBIT",
      "CREDIT",
      "DEBIT",
      "CREDIT",
      "DEBIT",
      "CREDIT",
      "DEBIT",
      "CREDIT",
      "DEBIT",
      "CREDIT",
      "DEBIT",
      "CREDIT",
    ]);

    for (const row of data) {
      aoa.push([
        row.compte ?? "",
        formatNumber(row.balance_entree_debit),
        formatNumber(row.balance_entree_credit),
        formatNumber(row.operation_gestion_debit),
        formatNumber(row.operation_gestion_credit),
        formatNumber(row.total_general_debit),
        formatNumber(row.total_general_credit),
        formatNumber(row.solde_debit),
        formatNumber(row.solde_credit),
        formatNumber(row.operation_fin_gestion_debit),
        formatNumber(row.operation_fin_gestion_credit),
        formatNumber(row.balance_sortie_debit),
        formatNumber(row.balance_sortie_credit),
      ]);
    }

    const worksheet = XLSX.utils.aoa_to_sheet(aoa);

    worksheet["!cols"] = [
      { wch: 14 },
      { wch: 18 },
      { wch: 18 },
      { wch: 18 },
      { wch: 18 },
      { wch: 18 },
      { wch: 18 },
      { wch: 18 },
      { wch: 18 },
      { wch: 18 },
      { wch: 18 },
      { wch: 18 },
      { wch: 18 },
    ];

    worksheet["!merges"] = [
      { s: { r: 0, c: 0 }, e: { r: 0, c: 12 } },
      { s: { r: 1, c: 0 }, e: { r: 2, c: 0 } },
      { s: { r: 1, c: 1 }, e: { r: 1, c: 2 } },
      { s: { r: 1, c: 3 }, e: { r: 1, c: 4 } },
      { s: { r: 1, c: 5 }, e: { r: 1, c: 6 } },
      { s: { r: 1, c: 7 }, e: { r: 1, c: 8 } },
      { s: { r: 1, c: 9 }, e: { r: 1, c: 10 } },
      { s: { r: 1, c: 11 }, e: { r: 1, c: 12 } },
    ];

    // Styles
    const thin = { style: "thin", color: { rgb: "000000" } };
    const border = { top: thin, bottom: thin, left: thin, right: thin };

    const headerStyle = {
      font: { bold: true, sz: 11 },
      alignment: { horizontal: "center", vertical: "center", wrapText: true },
      border,
      fill: { fgColor: { rgb: "E3F2FD" } },
    };

    const totalClassStyle = {
      font: { bold: true },
      alignment: { horizontal: "right", vertical: "center" },
      border,
      fill: { fgColor: { rgb: "D9D9D9" } },
    };

    const grandTotalStyle = {
      font: { bold: true },
      alignment: { horizontal: "right", vertical: "center" },
      border,
      fill: { fgColor: { rgb: "F2F2F2" } },
    };

    const accountStyle = {
      alignment: { horizontal: "right", vertical: "center" },
      border,
    };

    const accountCompteStyle = {
      font: { bold: true },
      alignment: { horizontal: "left", vertical: "center" },
      border,
    };

    // Styles sur les 3 lignes d'en-tête
    for (let r = 0; r <= 2; r++) {
      for (let c = 0; c <= 12; c++) {
        const addr = XLSX.utils.encode_cell({ r, c });
        if (!worksheet[addr]) worksheet[addr] = { t: "s", v: "" };
        worksheet[addr].s = headerStyle;
      }
    }

    // Styles sur les lignes de données
    for (let i = 0; i < data.length; i++) {
      const row = data[i];
      const r = i + 3;

      let styleRow;
      let styleCompte;
      if (row.type === "grand-total") {
        styleRow = grandTotalStyle;
        styleCompte = grandTotalStyle;
      } else if (row.type === "total-class") {
        styleRow = totalClassStyle;
        styleCompte = totalClassStyle;
      } else {
        styleRow = accountStyle;
        styleCompte = accountCompteStyle;
      }

      for (let c = 0; c <= 12; c++) {
        const addr = XLSX.utils.encode_cell({ r, c });
        if (!worksheet[addr]) worksheet[addr] = { t: "s", v: "" };
        worksheet[addr].s = c === 0 ? styleCompte : styleRow;
      }
    }

    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, "Consolidation Balance");

    const buffer = XLSX.write(workbook, {
      type: "buffer",
      bookType: "xlsx",
      cellStyles: true,
    });

    const outName =
      (filename || "consolidation-balance") + "-" + Date.now() + ".xlsx";
    res.setHeader(
      "Content-Type",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    );
    res.setHeader("Content-Disposition", `attachment; filename="${outName}"`);
    res.send(buffer);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: `Erreur lors de l'export: ${err.message}` });
  }
};
