<template>
  <div v-if="rows.length" class="datatable">
    <h3>Aperçu de la consolidation</h3>

    <div class="controls">
      <label>
        Lignes par page :
        <select v-model.number="rowsPerPage">
          <option :value="25">25</option>
          <option :value="50">50</option>
          <option :value="100">100</option>
          <option :value="500">500</option>
          <option :value="99999">Tout</option>
        </select>
      </label>
      <span class="counter">
        {{ startIndex + 1 }}–{{ Math.min(endIndex, rows.length) }} sur
        {{ rows.length }}
      </span>
    </div>

    <div class="table-wrapper">
      <table>
        <thead>
          <tr>
            <th rowspan="2" class="col-compte">N°COMPTE</th>
            <th colspan="2">BALANCE D'ENTREE</th>
            <th colspan="2">OPERATION GESTION</th>
            <th colspan="2">TOTAL GENERAL</th>
            <th colspan="2">SOLDE</th>
            <th colspan="2">OPERATION FIN GESTION</th>
            <th colspan="2">BALANCE DE SORTIE</th>
          </tr>
          <tr>
            <th>DEBIT</th>
            <th>CREDIT</th>
            <th>DEBIT</th>
            <th>CREDIT</th>
            <th>DEBIT</th>
            <th>CREDIT</th>
            <th>DEBIT</th>
            <th>CREDIT</th>
            <th>DEBIT</th>
            <th>CREDIT</th>
            <th>DEBIT</th>
            <th>CREDIT</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="(row, i) in paginatedRows"
            :key="i"
            :class="{
              'row-account': row.type === 'account',
              'row-total-class': row.type === 'total-class',
              'row-grand-total': row.type === 'grand-total',
            }"
          >
            <td class="col-compte">{{ row.compte }}</td>
            <td>{{ fmt(row.balance_entree_debit) }}</td>
            <td>{{ fmt(row.balance_entree_credit) }}</td>
            <td>{{ fmt(row.operation_gestion_debit) }}</td>
            <td>{{ fmt(row.operation_gestion_credit) }}</td>
            <td>{{ fmt(row.total_general_debit) }}</td>
            <td>{{ fmt(row.total_general_credit) }}</td>
            <td>{{ fmt(row.solde_debit) }}</td>
            <td>{{ fmt(row.solde_credit) }}</td>
            <td>{{ fmt(row.operation_fin_gestion_debit) }}</td>
            <td>{{ fmt(row.operation_fin_gestion_credit) }}</td>
            <td>{{ fmt(row.balance_sortie_debit) }}</td>
            <td>{{ fmt(row.balance_sortie_credit) }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="totalPages > 1" class="pagination">
      <button class="grey" :disabled="page === 1" @click="page--">
        ◀ Précédent
      </button>
      <span>Page {{ page }} / {{ totalPages }}</span>
      <button class="grey" :disabled="page === totalPages" @click="page++">
        Suivant ▶
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from "vue";

const props = defineProps({
  rows: { type: Array, default: () => [] },
});

const page = ref(1);
const rowsPerPage = ref(50);

watch(
  () => props.rows,
  () => {
    page.value = 1;
  },
);

const totalPages = computed(() =>
  rowsPerPage.value >= props.rows.length
    ? 1
    : Math.ceil(props.rows.length / rowsPerPage.value),
);

const startIndex = computed(() => (page.value - 1) * rowsPerPage.value);
const endIndex = computed(() => startIndex.value + rowsPerPage.value);

const paginatedRows = computed(() =>
  props.rows.slice(startIndex.value, endIndex.value),
);

function fmt(v) {
  if (v === null || v === undefined || v === "") return "";
  const n = Number(v);
  if (!Number.isFinite(n)) return String(v);
  if (n === 0) return "";
  return n.toLocaleString("fr-FR", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}
</script>

<style scoped>
.datatable {
  background: white;
  padding: 20px;
  border-radius: 10px;
  border: 1px solid #e0e0e0;
}

h3 {
  margin: 0 0 12px;
  font-size: 16px;
  color: #333;
}

.controls {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
  font-size: 13px;
  color: #555;
  flex-wrap: wrap;
  gap: 10px;
}

.controls select {
  margin-left: 6px;
  padding: 4px 8px;
  border-radius: 4px;
  border: 1px solid #cfd8dc;
  font-size: 13px;
}

.table-wrapper {
  overflow: auto;
  max-height: 600px;
  border: 1px solid #e0e0e0;
  border-radius: 6px;
}

table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
  background: white;
  white-space: nowrap;
}

th,
td {
  border: 1px solid #e0e0e0;
  padding: 6px 8px;
  text-align: right;
}

th {
  background: #e3f2fd;
  font-weight: 600;
  text-align: center;
  position: sticky;
  top: 0;
  z-index: 2;
}

thead tr:nth-child(2) th {
  top: 32px;
}

.col-compte {
  text-align: left;
  font-weight: 600;
  background: #e3f2fd;
  position: sticky;
  left: 0;
  z-index: 1;
}

tbody .col-compte {
  background: white;
  font-weight: 500;
}

.row-account .col-compte {
  background: white;
}

.row-total-class {
  background: #fff9c4 !important;
  font-weight: 700;
}

.row-total-class .col-compte {
  background: #fff9c4 !important;
  color: #f57f17;
}

.row-grand-total {
  background: #c8e6c9 !important;
  font-weight: 700;
}

.row-grand-total .col-compte {
  background: #c8e6c9 !important;
  color: #1b5e20;
}

.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 12px;
  margin-top: 14px;
  font-size: 13px;
  color: #555;
}

.pagination button {
  padding: 6px 12px;
  font-size: 12px;
}
</style>
