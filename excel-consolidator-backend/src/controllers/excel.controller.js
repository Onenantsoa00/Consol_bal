const XLSX = require("xlsx");
const fs = require("fs");

// Colonnes cibles dans l'ordre attendu
const COLS = [
  "N°COMPTE",
  "BALANCE_ENTREE_DEBIT",
  "BALANCE_ENTREE_CREDIT",
  "OPERATION_GESTION_DEBIT",
  "OPERATION_GESTION_CREDIT",
  "TOTAL_GENERAL_DEBIT",
  "TOTAL_GENERAL_CREDIT",
  "SOLDE_DEBIT",
  "SOLDE_CREDIT",
  "OPERATION_FIN_GESTION_DEBIT",
  "OPERATION_FIN_GESTION_CREDIT",
  "BALANCE_SORTIE_DEBIT",
  "BALANCE_SORTIE_CREDIT",
];

/**
 * Vérifie si une valeur est un numéro de compte plausible
 * - uniquement des chiffres
 * - longueur entre 3 et 10
 * - pas un montant (pas de point décimal)
 */
function isAccountNumber(value) {
  if (value === null || value === undefined) return false;
  const s = String(value).trim();
  if (!s) return false;
  if (!/^\d{3,10}$/.test(s)) return false;
  return true;
}

/**
 * Convertit une valeur en nombre sûr
 */
function toNumber(v) {
  if (v === null || v === undefined || v === "") return 0;
  if (typeof v === "number") return v;
  const s = String(v).replace(/\s/g, "").replace(",", ".");
  const n = parseFloat(s);
  return Number.isFinite(n) ? n : 0;
}

/**
 * Détecte le numéro de classe (1er chiffre du compte)
 */
function getClasse(account) {
  const s = String(account).trim();
  return s.charAt(0); // '1', '2', '4', '5', '6', ...
}

/**
 * Extrait les lignes de comptes d'une feuille
 */
function extractAccountsFromSheet(sheet) {
  const rows = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: "" });
  const accounts = [];

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    const colA = row[0];

    // Ignorer les lignes sans compte valide
    if (!isAccountNumber(colA)) continue;

    // Ignorer les lignes de totaux qui contiendraient un n° dans la 1ère colonne
    // (peu probable mais sécurité)
    const labelB = String(row[1] ?? "").trim();
    if (labelB.toLowerCase().startsWith("total")) continue;

    accounts.push({
      compte: String(colA).trim(),
      classe: getClasse(colA),
      balance_entree_debit: toNumber(row[1]),
      balance_entree_credit: toNumber(row[2]),
      operation_gestion_debit: toNumber(row[3]),
      operation_gestion_credit: toNumber(row[4]),
      total_general_debit: toNumber(row[5]),
      total_general_credit: toNumber(row[6]),
      solde_debit: toNumber(row[7]),
      solde_credit: toNumber(row[8]),
      operation_fin_gestion_debit: toNumber(row[9]),
      operation_fin_gestion_credit: toNumber(row[10]),
      balance_sortie_debit: toNumber(row[11]),
      balance_sortie_credit: toNumber(row[12]),
    });
  }

  return accounts;
}

/**
 * Additionne deux ensembles de valeurs numériques
 */
function addValues(a, b) {
  return {
    balance_entree_debit: a.balance_entree_debit + b.balance_entree_debit,
    balance_entree_credit: a.balance_entree_credit + b.balance_entree_credit,
    operation_gestion_debit:
      a.operation_gestion_debit + b.operation_gestion_debit,
    operation_gestion_credit:
      a.operation_gestion_credit + b.operation_gestion_credit,
    total_general_debit: a.total_general_debit + b.total_general_debit,
    total_general_credit: a.total_general_credit + b.total_general_credit,
    solde_debit: a.solde_debit + b.solde_debit,
    solde_credit: a.solde_credit + b.solde_credit,
    operation_fin_gestion_debit:
      a.operation_fin_gestion_debit + b.operation_fin_gestion_debit,
    operation_fin_gestion_credit:
      a.operation_fin_gestion_credit + b.operation_fin_gestion_credit,
    balance_sortie_debit: a.balance_sortie_debit + b.balance_sortie_debit,
    balance_sortie_credit: a.balance_sortie_credit + b.balance_sortie_credit,
  };
}

function emptyValues() {
  return {
    balance_entree_debit: 0,
    balance_entree_credit: 0,
    operation_gestion_debit: 0,
    operation_gestion_credit: 0,
    total_general_debit: 0,
    total_general_credit: 0,
    solde_debit: 0,
    solde_credit: 0,
    operation_fin_gestion_debit: 0,
    operation_fin_gestion_credit: 0,
    balance_sortie_debit: 0,
    balance_sortie_credit: 0,
  };
}

/**
 * Consolide les comptes : regroupe par classe et calcule les totaux
 */
function consolidateAccounts(allAccounts) {
  // 1. Regrouper par classe
  const byClass = {};
  for (const acc of allAccounts) {
    const c = acc.classe;
    if (!byClass[c]) byClass[c] = [];
    byClass[c].push(acc);
  }

  // 2. Trier les classes numériquement
  const sortedClasses = Object.keys(byClass).sort(
    (a, b) => Number(a) - Number(b),
  );

  const result = [];
  const grandTotal = emptyValues();
  const fileDetails = [];

  for (const c of sortedClasses) {
    // Trier les comptes à l'intérieur de la classe par n° croissant
    const accounts = byClass[c].sort((a, b) =>
      a.compte.localeCompare(b.compte, undefined, { numeric: true }),
    );

    const classTotal = emptyValues();

    for (const acc of accounts) {
      // Ligne de compte
      result.push({
        type: "account",
        compte: acc.compte,
        classe: c,
        ...acc,
      });

      // Cumul
      Object.assign(classTotal, addValues(classTotal, acc));
      Object.assign(grandTotal, addValues(grandTotal, acc));
    }

    // Ligne Total Cl. X
    result.push({
      type: "total-class",
      compte: `Total Cl. ${c}`,
      classe: c,
      ...classTotal,
    });
  }

  // Ligne TOT. GEN.
  result.push({
    type: "grand-total",
    compte: "TOT. GEN.",
    classe: "",
    ...grandTotal,
  });

  return {
    rows: result,
    grandTotal,
    details: fileDetails,
    classes: sortedClasses,
  };
}

/**
 * POST /api/excel/consolidate
 */
exports.consolidate = async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ error: "Aucun fichier reçu." });
    }

    const allAccounts = [];
    const fileInfos = [];

    for (const file of req.files) {
      const workbook = XLSX.readFile(file.path);
      let fileAccounts = 0;

      // Parcourir TOUTES les feuilles (certains fichiers ont plusieurs feuilles)
      for (const sheetName of workbook.SheetNames) {
        const sheet = workbook.Sheets[sheetName];
        if (!sheet || !sheet["!ref"]) continue; // feuille vide

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

      // Nettoyage du fichier temporaire
      try {
        fs.unlinkSync(file.path);
      } catch (_) {
        /* ignore */
      }
    }

    if (allAccounts.length === 0) {
      return res.status(400).json({
        error:
          "Aucun compte détecté. Vérifiez que la colonne A contient bien des numéros de compte (ex: 1837, 401321).",
      });
    }

    // Déduplication optionnelle : si le même compte apparaît dans plusieurs fichiers,
    // on additionne les valeurs (car chaque fichier est une balance différente)
    const consolidated = consolidateAccounts(allAccounts);

    res.json({
      success: true,
      filesProcessed: req.files.length,
      totalAccounts: allAccounts.length,
      totalRows: consolidated.rows.length,
      classes: consolidated.classes,
      data: consolidated.rows,
      grandTotal: consolidated.grandTotal,
      details: fileInfos,
    });
  } catch (err) {
    console.error(err);
    res
      .status(500)
      .json({ error: `Erreur lors de la consolidation: ${err.message}` });
  }
};

/**
 * POST /api/excel/export
 * Reçoit { data: [...rows], filename: 'consolidation' }
 * Génère un fichier Excel au format "Balance Générale"
 */
exports.exportExcel = (req, res) => {
  try {
    const { data, filename } = req.body;

    if (!Array.isArray(data) || data.length === 0) {
      return res.status(400).json({ error: "Aucune donnée à exporter." });
    }

    // === Construction de la feuille Excel ===
    const aoa = []; // array of arrays

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

    // Ligne 2 : En-tête niveau 1 (fusions)
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

    // Lignes de données
    for (const row of data) {
      aoa.push([
        row.compte ?? "",
        row.balance_entree_debit ?? "",
        row.balance_entree_credit ?? "",
        row.operation_gestion_debit ?? "",
        row.operation_gestion_credit ?? "",
        row.total_general_debit ?? "",
        row.total_general_credit ?? "",
        row.solde_debit ?? "",
        row.solde_credit ?? "",
        row.operation_fin_gestion_debit ?? "",
        row.operation_fin_gestion_credit ?? "",
        row.balance_sortie_debit ?? "",
        row.balance_sortie_credit ?? "",
      ]);
    }

    const worksheet = XLSX.utils.aoa_to_sheet(aoa);

    // Largeur des colonnes
    worksheet["!cols"] = [
      { wch: 14 }, // N°COMPTE
      { wch: 16 },
      { wch: 16 },
      { wch: 16 },
      { wch: 16 },
      { wch: 16 },
      { wch: 16 },
      { wch: 16 },
      { wch: 16 },
      { wch: 16 },
      { wch: 16 },
      { wch: 16 },
      { wch: 16 },
    ];

    // Fusions de l'en-tête
    worksheet["!merges"] = [
      // Titre sur toute la largeur
      { s: { r: 0, c: 0 }, e: { r: 0, c: 12 } },
      // N°COMPTE (ligne 2 et 3)
      { s: { r: 1, c: 0 }, e: { r: 2, c: 0 } },
      // Chaque groupe débit/crédit
      { s: { r: 1, c: 1 }, e: { r: 1, c: 2 } },
      { s: { r: 1, c: 3 }, e: { r: 1, c: 4 } },
      { s: { r: 1, c: 5 }, e: { r: 1, c: 6 } },
      { s: { r: 1, c: 7 }, e: { r: 1, c: 8 } },
      { s: { r: 1, c: 9 }, e: { r: 1, c: 10 } },
      { s: { r: 1, c: 11 }, e: { r: 1, c: 12 } },
    ];

    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, "Consolidation Balance");

    const buffer = XLSX.write(workbook, { type: "buffer", bookType: "xlsx" });

    const outName = (filename || "consolidation") + "-" + Date.now() + ".xlsx";
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
