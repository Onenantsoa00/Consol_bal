<template>
  <div class="app">
    <header>
      <h1>📊 Consolidation Balance</h1>
      <p class="subtitle">
        Importez jusqu'à 30 balances générales Excel pour les consolider par
        classe de comptes
      </p>
    </header>

    <section class="card">
      <FileUploader v-model:files="files" :disabled="loading" />

      <div class="actions">
        <button
          class="primary"
          :disabled="!files.length || loading || files.length > 30"
          @click="handleConsolidate"
        >
          {{ loading ? "⏳ Traitement..." : "🔀 Consolider" }}
        </button>

        <button
          class="secondary"
          :disabled="!rows.length || loading"
          @click="handleExport"
        >
          ⬇️ Exporter en Excel
        </button>

        <button
          class="grey"
          :disabled="loading || (!files.length && !rows.length)"
          @click="reset"
        >
          🔄 Réinitialiser
        </button>
      </div>

      <div v-if="error" class="error">❌ {{ error }}</div>
      <div v-if="successMsg" class="success">✅ {{ successMsg }}</div>
    </section>

    <ConsolidationSummary :summary="summary" />

    <DataTable :rows="rows" />
  </div>
</template>

<script setup>
import { ref } from "vue";
import FileUploader from "./components/FileUploader.vue";
import ConsolidationSummary from "./components/ConsolidationSummary.vue";
import DataTable from "./components/DataTable.vue";
import { consolidateFiles, exportConsolidated } from "./services/api";

const files = ref([]);
const rows = ref([]);
const summary = ref(null);
const loading = ref(false);
const error = ref("");
const successMsg = ref("");

async function handleConsolidate() {
  error.value = "";
  successMsg.value = "";

  if (loading.value) return;

  if (files.value.length > 30) {
    error.value = "Maximum 30 fichiers autorisés.";
    return;
  }

  loading.value = true;

  try {
    const result = await consolidateFiles(files.value);
    rows.value = result.data;
    summary.value = {
      filesProcessed: result.filesProcessed,
      totalAccounts: result.totalAccounts,
      totalRows: result.totalRows,
      classes: result.classes,
      details: result.details,
    };
    successMsg.value = `${result.totalAccounts} compte(s) unique(s) consolidé(s) — ${result.totalRows} ligne(s) générée(s).`;
  } catch (err) {
    error.value =
      err.response?.data?.error ||
      err.message ||
      "Erreur lors de la consolidation.";
  } finally {
    loading.value = false;
  }
}

async function handleExport() {
  error.value = "";
  successMsg.value = "";
  loading.value = true;

  try {
    const blob = await exportConsolidated(rows.value, "consolidation-balance");

    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `Consolidation Balance-${Date.now()}.xlsx`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);

    successMsg.value = "Export Excel réussi ✅";
  } catch (err) {
    error.value = "Erreur lors de l'export.";
  } finally {
    loading.value = false;
  }
}

function reset() {
  files.value = [];
  rows.value = [];
  summary.value = null;
  error.value = "";
  successMsg.value = "";
}
</script>

<style scoped>
.app {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

header {
  text-align: center;
  padding: 10px 0;
}

h1 {
  margin: 0;
  font-size: 26px;
  color: #1976d2;
}

.subtitle {
  margin: 6px 0 0;
  color: #607d8b;
  font-size: 14px;
}

.card {
  background: white;
  padding: 20px;
  border-radius: 10px;
  border: 1px solid #e0e0e0;
}

.actions {
  display: flex;
  gap: 10px;
  margin-top: 16px;
  flex-wrap: wrap;
}

.error {
  margin-top: 12px;
  padding: 10px 14px;
  background: #ffebee;
  color: #c62828;
  border-radius: 6px;
  font-size: 13px;
  border-left: 4px solid #c62828;
}

.success {
  margin-top: 12px;
  padding: 10px 14px;
  background: #e8f5e9;
  color: #2e7d32;
  border-radius: 6px;
  font-size: 13px;
  border-left: 4px solid #2e7d32;
}
</style>
