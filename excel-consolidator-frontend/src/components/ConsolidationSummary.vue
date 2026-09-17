<template>
  <div v-if="summary" class="summary">
    <h3>Résumé de la consolidation</h3>

    <div class="chips">
      <span class="chip blue">📄 {{ summary.filesProcessed }} fichier(s)</span>
      <span class="chip green">🧾 {{ summary.totalAccounts }} compte(s)</span>
      <span class="chip orange"
        >📊 {{ summary.totalRows }} ligne(s) au total</span
      >
      <span class="chip purple"
        >📚 Classes : {{ summary.classes.join(", ") }}</span
      >
    </div>

    <ul class="details">
      <li v-for="(d, i) in summary.details" :key="i">
        <span class="name">📎 {{ d.name }}</span>
        <span class="meta">{{ d.accounts }} compte(s) extrait(s)</span>
      </li>
    </ul>
  </div>
</template>

<script setup>
defineProps({
  summary: { type: Object, default: null },
});
</script>

<style scoped>
.summary {
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

.chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 16px;
}

.chip {
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 500;
  color: white;
}

.chip.blue {
  background: #1976d2;
}
.chip.green {
  background: #43a047;
}
.chip.orange {
  background: #fb8c00;
}
.chip.purple {
  background: #8e24aa;
}

.details {
  list-style: none;
  padding: 0;
  margin: 0;
  border-top: 1px solid #f0f0f0;
}

.details li {
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
  font-size: 13px;
  gap: 12px;
  flex-wrap: wrap;
}

.details li:last-child {
  border-bottom: none;
}

.name {
  color: #333;
  font-weight: 500;
}

.meta {
  color: #757575;
}
</style>
