import {
  createDonation,
  createExpense,
  createNgo,
  fileToBase64,
  getApiUrl,
  getNgo,
  listDonations,
  listExpenses,
  listNgos,
  setApiUrl,
  uploadReceipt,
} from "./api.js";

const app = document.getElementById("app");

function formatMoney(value) {
  return Number(value).toLocaleString("pt-BR", {
    style: "currency",
    currency: "BRL",
  });
}

function formatDate(iso) {
  if (!iso) return "—";
  return new Date(iso).toLocaleString("pt-BR", {
    dateStyle: "short",
    timeStyle: "short",
  });
}

function el(tag, attrs = {}, children = []) {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (k === "class") node.className = v;
    else if (k === "text") node.textContent = v;
    else if (k.startsWith("on") && typeof v === "function")
      node.addEventListener(k.slice(2).toLowerCase(), v);
    else if (v != null) node.setAttribute(k, v);
  }
  for (const child of [].concat(children)) {
    if (child == null) continue;
    node.appendChild(typeof child === "string" ? document.createTextNode(child) : child);
  }
  return node;
}

function showToast(message, type = "error") {
  const toast = el("div", { class: `toast toast-${type}`, text: message });
  document.body.appendChild(toast);
  requestAnimationFrame(() => toast.classList.add("show"));
  setTimeout(() => {
    toast.classList.remove("show");
    setTimeout(() => toast.remove(), 300);
  }, 4000);
}

function parseRoute() {
  const hash = location.hash.replace(/^#/, "") || "/";
  const parts = hash.split("/").filter(Boolean);
  if (parts[0] === "ngos" && parts[1]) return { view: "detail", ngoId: parts[1] };
  return { view: "list" };
}

function renderShell(content, { title, back } = {}) {
  app.replaceChildren(
    el("div", { class: "layout" }, [
      el("header", { class: "header" }, [
        el("div", { class: "brand" }, [
          el("span", { class: "brand-icon", text: "🐾" }),
          el("h1", { text: "NGO Tracker" }),
        ]),
        el("p", { class: "tagline", text: "Auditoria de doações e gastos" }),
      ]),
      el("nav", { class: "toolbar" }, [
        back
          ? el("a", { href: "#/", class: "btn btn-ghost", text: "← ONGs" })
          : el("span"),
        el("button", {
          class: "btn btn-ghost",
          text: "⚙ Configurações",
          onclick: () => renderSettings(),
        }),
      ]),
      title ? el("h2", { class: "page-title", text: title }) : null,
      content,
      el("footer", { class: "footer", text: "NGO Tracker · resgate animal" }),
    ])
  );
}

function renderSettings() {
  const input = el("input", {
    type: "url",
    class: "input",
    placeholder: "https://....execute-api.us-east-1.amazonaws.com/dev",
    value: getApiUrl(),
  });

  renderShell(
    el("section", { class: "card" }, [
      el("h3", { text: "URL da API" }),
      el("p", { class: "hint", text: "Cole o valor de terraform output -raw api_gateway_url" }),
      input,
      el("div", { class: "actions" }, [
        el("button", {
          class: "btn btn-primary",
          text: "Salvar",
          onclick: () => {
            setApiUrl(input.value.trim());
            showToast("URL salva.", "success");
            render();
          },
        }),
      ]),
    ]),
    { title: "Configurações" }
  );
}

async function renderList() {
  renderShell(el("div", { class: "loading", text: "Carregando ONGs…" }));

  try {
    const { ngos } = await listNgos();

    const list =
      ngos.length === 0
        ? el("p", { class: "empty", text: "Nenhuma ONG cadastrada ainda." })
        : el(
            "ul",
            { class: "ngo-list" },
            ngos.map((ngo) =>
              el("li", {}, [
                el("a", { href: `#/ngos/${ngo.ngo_id}`, class: "ngo-card" }, [
                  el("strong", { text: ngo.name }),
                  el("span", { class: "meta", text: ngo.city || "—" }),
                  ngo.description
                    ? el("p", { class: "desc", text: ngo.description })
                    : null,
                ]),
              ])
            )
          );

    const form = el("form", { class: "card form-card" }, [
      el("h3", { text: "Nova ONG" }),
      field("Nome", "text", "name", { required: true }),
      field("Cidade", "text", "city"),
      field("Descrição", "textarea", "description"),
      el("button", { class: "btn btn-primary", type: "submit", text: "Cadastrar ONG" }),
    ]);

    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      const fd = new FormData(form);
      try {
        const { ngo } = await createNgo({
          name: fd.get("name"),
          city: fd.get("city"),
          description: fd.get("description"),
        });
        showToast("ONG criada.", "success");
        location.hash = `#/ngos/${ngo.ngo_id}`;
        render();
      } catch (err) {
        showToast(err.message);
      }
    });

    renderShell(
      el("div", { class: "grid" }, [
        el("section", { class: "card" }, [el("h3", { text: "ONGs" }), list]),
        form,
      ])
    );
  } catch (err) {
    renderShell(
      el("div", { class: "card error-card" }, [
        el("p", { text: err.message }),
        el("button", {
          class: "btn btn-primary",
          text: "Configurar API",
          onclick: () => renderSettings(),
        }),
      ])
    );
  }
}

function field(label, type, name, opts = {}) {
  const input =
    type === "textarea"
      ? el("textarea", { class: "input", name, rows: "2", ...opts })
      : el("input", { class: "input", type, name, ...opts });
  if (type === "number") input.step = "0.01";
  return el("label", { class: "field" }, [
    el("span", { text: label }),
    input,
  ]);
}

async function renderDetail(ngoId) {
  renderShell(el("div", { class: "loading", text: "Carregando…" }), {
    back: true,
  });

  try {
    const [profile, donationsRes, expensesRes] = await Promise.all([
      getNgo(ngoId),
      listDonations(ngoId),
      listExpenses(ngoId),
    ]);

    const { ngo, summary } = profile;
    const donations = donationsRes.donations;
    const expenses = expensesRes.expenses;

    const summaryCards = el("div", { class: "summary" }, [
      statCard("Doações", formatMoney(summary.total_donations), summary.donation_count),
      statCard("Gastos", formatMoney(summary.total_expenses), summary.expense_count),
      statCard("Saldo", formatMoney(summary.balance), null, summary.balance >= 0),
    ]);

    const donationForm = transactionForm("Doação", [
      field("Valor (R$)", "number", "amount", { required: true, min: "0.01" }),
      field("Doador", "text", "donor_name"),
      field("Observações", "textarea", "notes"),
    ], async (fd) => {
      await createDonation(ngoId, {
        amount: parseFloat(fd.get("amount")),
        donor_name: fd.get("donor_name"),
        notes: fd.get("notes"),
      });
    });

    const expenseForm = transactionForm("Gasto", [
      field("Valor (R$)", "number", "amount", { required: true, min: "0.01" }),
      el("label", { class: "field" }, [
        el("span", { text: "Categoria" }),
        el(
          "select",
          { class: "input", name: "category", required: true },
          [
            "veterinario",
            "racao",
            "medicamentos",
            "hospedagem",
            "outros",
          ].map((c) => el("option", { value: c, text: c }))
        ),
      ]),
      field("Descrição", "textarea", "description"),
    ], async (fd) => {
      await createExpense(ngoId, {
        amount: parseFloat(fd.get("amount")),
        category: fd.get("category"),
        description: fd.get("description"),
      });
    });

    const receiptForm = el("form", { class: "form-inline" }, [
      el("h4", { text: "Comprovante" }),
      el("input", { type: "file", name: "file", class: "input", required: true }),
      el("button", { class: "btn btn-secondary", type: "submit", text: "Enviar para S3" }),
    ]);
    receiptForm.addEventListener("submit", async (e) => {
      e.preventDefault();
      const file = receiptForm.querySelector('[name="file"]').files[0];
      if (!file) return;
      try {
        const b64 = await fileToBase64(file);
        await uploadReceipt(ngoId, file.name, b64);
        showToast("Comprovante enviado.", "success");
      } catch (err) {
        showToast(err.message);
      }
    });

    renderShell(
      el("div", { class: "detail" }, [
        el("section", { class: "card hero" }, [
          el("h2", { text: ngo.name }),
          el("p", { class: "meta", text: `${ngo.city || "—"} · cadastro ${formatDate(ngo.created_at)}` }),
          ngo.description ? el("p", { text: ngo.description }) : null,
          summaryCards,
        ]),
        el("div", { class: "grid-2" }, [
          el("section", { class: "card" }, [
            el("h3", { text: "Doações" }),
            transactionList(donations, (d) => [
              el("strong", { text: formatMoney(d.amount) }),
              d.donor_name ? el("span", { text: ` · ${d.donor_name}` }) : null,
              el("time", { class: "meta", text: formatDate(d.created_at) }),
            ]),
            donationForm,
          ]),
          el("section", { class: "card" }, [
            el("h3", { text: "Gastos" }),
            transactionList(expenses, (e) => [
              el("strong", { text: formatMoney(e.amount) }),
              el("span", { text: ` · ${e.category}` }),
              e.description ? el("p", { class: "desc", text: e.description }) : null,
              el("time", { class: "meta", text: formatDate(e.created_at) }),
            ]),
            expenseForm,
          ]),
        ]),
        el("section", { class: "card" }, [receiptForm]),
      ]),
      { title: ngo.name, back: true }
    );
  } catch (err) {
    renderShell(
      el("div", { class: "card error-card" }, [
        el("p", { text: err.message }),
        el("a", { href: "#/", class: "btn btn-ghost", text: "Voltar" }),
      ]),
      { back: true }
    );
  }
}

function statCard(label, value, count, positive = true) {
  return el("div", { class: `stat ${positive ? "positive" : "negative"}` }, [
    el("span", { class: "stat-label", text: label }),
    el("strong", { class: "stat-value", text: value }),
    count != null ? el("span", { class: "stat-count", text: `${count} registro(s)` }) : null,
  ]);
}

function transactionList(items, renderItem) {
  if (!items.length) return el("p", { class: "empty", text: "Nenhum registro." });
  return el(
    "ul",
    { class: "tx-list" },
    items.map((item) => el("li", {}, renderItem(item)))
  );
}

function transactionForm(title, fields, onSubmit) {
  const form = el("form", { class: "form-inline" }, [
    el("h4", { text: `Registrar ${title}` }),
    ...fields,
    el("button", {
      class: "btn btn-primary",
      type: "submit",
      text: `Salvar ${title.toLowerCase()}`,
    }),
  ]);
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    try {
      await onSubmit(new FormData(form));
      showToast(`${title} registrada.`, "success");
      render();
    } catch (err) {
      showToast(err.message);
    }
  });
  return form;
}

function render() {
  const route = parseRoute();
  if (!getApiUrl() && route.view !== "settings") {
    renderSettings();
    return;
  }
  if (route.view === "detail") renderDetail(route.ngoId);
  else renderList();
}

window.addEventListener("hashchange", render);
render();
