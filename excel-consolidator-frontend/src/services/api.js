import axios from "axios";

const api = axios.create({
  baseURL: "http://localhost:3000/api",
  timeout: 180000, // 3 minutes pour gérer jusqu'à 30 fichiers
});

/**
 * Envoie les fichiers au backend pour consolidation.
 * @param {File[]} files
 */
export async function consolidateFiles(files) {
  const formData = new FormData();
  files.forEach((file) => formData.append("files", file));

  const { data } = await api.post("/excel/consolidate", formData, {
    headers: { "Content-Type": "multipart/form-data" },
  });
  return data;
}

/**
 * Demande au backend de générer un fichier Excel et le télécharge.
 * @param {object[]} data
 * @param {string} filename
 */
export async function exportConsolidated(
  data,
  filename = "consolidation-balance",
) {
  const response = await api.post(
    "/excel/export",
    { data, filename },
    { responseType: "blob" },
  );
  return response.data;
}
