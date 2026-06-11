const STORAGE_KEY = "ngo-tracker-api-url";

export function getApiUrl() {
  return (
    localStorage.getItem(STORAGE_KEY) ||
    import.meta.env.VITE_API_URL ||
    ""
  ).replace(/\/$/, "");
}

export function setApiUrl(url) {
  localStorage.setItem(STORAGE_KEY, url.replace(/\/$/, ""));
}

export async function api(path, options = {}) {
  const base = getApiUrl();
  if (!base) {
    throw new Error("Configure a URL da API nas configurações.");
  }

  const hasBody = options.body != null;
  const headers = { ...options.headers };
  if (hasBody) {
    headers["Content-Type"] = "application/json";
  }

  const res = await fetch(`${base}${path}`, {
    ...options,
    headers,
  });

  let data = {};
  try {
    data = await res.json();
  } catch {
    /* resposta não-JSON */
  }

  if (!res.ok) {
    const msg = data.error || data.detail || res.statusText;
    throw new Error(msg);
  }

  return data;
}

export const listNgos = () => api("/ngos");
export const createNgo = (body) =>
  api("/ngos", { method: "POST", body: JSON.stringify(body) });
export const getNgo = (id) => api(`/ngos/${id}`);
export const listDonations = (id) => api(`/ngos/${id}/donations`);
export const createDonation = (id, body) =>
  api(`/ngos/${id}/donations`, { method: "POST", body: JSON.stringify(body) });
export const listExpenses = (id) => api(`/ngos/${id}/expenses`);
export const createExpense = (id, body) =>
  api(`/ngos/${id}/expenses`, { method: "POST", body: JSON.stringify(body) });
export const uploadReceipt = (id, filename, contentBase64) =>
  api(`/ngos/${id}/receipts`, {
    method: "POST",
    body: JSON.stringify({ filename, content_base64: contentBase64 }),
  });

export function fileToBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      const result = reader.result;
      const base64 = String(result).split(",")[1] || "";
      resolve(base64);
    };
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}
