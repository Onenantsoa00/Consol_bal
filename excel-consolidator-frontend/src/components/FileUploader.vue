<template>
  <div class="uploader">
    <label class="drop-zone" :class="{ 'has-files': files.length }">
      <input
        type="file"
        multiple
        accept=".xlsx,.xls,.csv"
        :disabled="disabled"
        @change="onChange"
      />
      <div class="drop-zone-content">
        <div class="icon">📁</div>
        <div class="title">
          {{
            files.length
              ? `${files.length} fichier(s) sélectionné(s)`
              : "Cliquez pour choisir des fichiers Excel"
          }}
        </div>
        <div class="subtitle">
          Formats acceptés : .xlsx, .xls (balances générales)
        </div>
      </div>
    </label>

    <ul v-if="files.length" class="file-list">
      <li v-for="(f, i) in files" :key="i">
        <span class="filename">{{ f.name }}</span>
        <span class="size">{{ formatSize(f.size) }}</span>
      </li>
    </ul>
  </div>
</template>

<script setup>
const props = defineProps({
  files: { type: Array, default: () => [] },
  disabled: { type: Boolean, default: false },
});

const emit = defineEmits(["update:files"]);

function onChange(event) {
  const selected = Array.from(event.target.files || []);
  emit("update:files", selected);
}

function formatSize(bytes) {
  if (bytes < 1024) return bytes + " B";
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB";
  return (bytes / 1024 / 1024).toFixed(1) + " MB";
}
</script>

<style scoped>
.uploader {
  width: 100%;
}

.drop-zone {
  display: block;
  border: 2px dashed #b0bec5;
  border-radius: 10px;
  padding: 30px;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s;
  background: white;
}

.drop-zone:hover:not(.has-files) {
  border-color: #1976d2;
  background: #f0f7ff;
}

.drop-zone.has-files {
  border-color: #43a047;
  background: #f1f8e9;
}

.drop-zone input[type="file"] {
  display: none;
}

.drop-zone-content .icon {
  font-size: 42px;
}

.drop-zone-content .title {
  font-size: 16px;
  font-weight: 500;
  margin-top: 8px;
  color: #333;
}

.drop-zone-content .subtitle {
  font-size: 12px;
  color: #757575;
  margin-top: 4px;
}

.file-list {
  list-style: none;
  padding: 0;
  margin: 12px 0 0;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid #e0e0e0;
}

.file-list li {
  display: flex;
  justify-content: space-between;
  padding: 8px 14px;
  border-bottom: 1px solid #f0f0f0;
  font-size: 13px;
}

.file-list li:last-child {
  border-bottom: none;
}

.filename {
  color: #333;
}

.size {
  color: #757575;
}
</style>
