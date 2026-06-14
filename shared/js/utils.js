// =====================================================================
// utils.js
// Shared helper / utility functions used across modules.
// =====================================================================

const Utils = {
  // -----------------------------------------------------------------
  // Board -> Class options
  // -----------------------------------------------------------------
  boardClasses: {
    WBCHSE: ["1st Semester", "2nd Semester", "3rd Semester", "4th Semester"],
    CBSE: ["Class 11", "Class 12"]
  },

  // -----------------------------------------------------------------
  // Populate a <select> with board options
  // -----------------------------------------------------------------
  fillBoardSelect(selectEl) {
    selectEl.innerHTML = `<option value="">-- Select Board --</option>`;
    Object.keys(this.boardClasses).forEach(b => {
      const opt = document.createElement("option");
      opt.value = b;
      opt.textContent = b;
      selectEl.appendChild(opt);
    });
  },

  // -----------------------------------------------------------------
  // Populate a <select> with class options based on board
  // -----------------------------------------------------------------
  fillClassSelect(selectEl, board) {
    selectEl.innerHTML = `<option value="">-- Select Class --</option>`;
    const classes = this.boardClasses[board] || [];
    classes.forEach(c => {
      const opt = document.createElement("option");
      opt.value = c;
      opt.textContent = c;
      selectEl.appendChild(opt);
    });
  },

  // -----------------------------------------------------------------
  // Format date
  // -----------------------------------------------------------------
  formatDate(dateStr) {
    if (!dateStr) return "-";
    const d = new Date(dateStr);
    return d.toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" });
  },

  formatDateTime(dateStr) {
    if (!dateStr) return "-";
    const d = new Date(dateStr);
    return d.toLocaleString("en-IN", { day: "2-digit", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" });
  },

  // -----------------------------------------------------------------
  // Current month string YYYY-MM
  // -----------------------------------------------------------------
  currentMonth() {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
  },

  // -----------------------------------------------------------------
  // Show toast / alert message
  // -----------------------------------------------------------------
  toast(message, type = "info") {
    let container = document.getElementById("toast-container");
    if (!container) {
      container = document.createElement("div");
      container.id = "toast-container";
      container.style.position = "fixed";
      container.style.top = "16px";
      container.style.right = "16px";
      container.style.zIndex = "9999";
      container.style.display = "flex";
      container.style.flexDirection = "column";
      container.style.gap = "8px";
      document.body.appendChild(container);
    }

    const toast = document.createElement("div");
    toast.textContent = message;
    toast.style.padding = "12px 18px";
    toast.style.borderRadius = "8px";
    toast.style.color = "#fff";
    toast.style.fontSize = "14px";
    toast.style.boxShadow = "0 2px 10px rgba(0,0,0,0.15)";
    toast.style.minWidth = "200px";
    toast.style.maxWidth = "320px";
    toast.style.animation = "fadeInUp 0.25s ease";

    const colors = {
      info: "#2563eb",
      success: "#16a34a",
      error: "#dc2626",
      warning: "#d97706"
    };
    toast.style.background = colors[type] || colors.info;

    container.appendChild(toast);
    setTimeout(() => {
      toast.style.opacity = "0";
      toast.style.transition = "opacity 0.3s";
      setTimeout(() => toast.remove(), 300);
    }, 3000);
  },

  // -----------------------------------------------------------------
  // Generate a random temporary password
  // -----------------------------------------------------------------
  generateTempPassword(length = 8) {
    const chars = "ABCDEFGHJKMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#$";
    let pass = "";
    for (let i = 0; i < length; i++) {
      pass += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return pass;
  },

  // -----------------------------------------------------------------
  // Escape HTML to prevent XSS when inserting user content
  // -----------------------------------------------------------------
  escapeHtml(str) {
    if (str === null || str === undefined) return "";
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  },

  // -----------------------------------------------------------------
  // Currency formatting (INR)
  // -----------------------------------------------------------------
  formatCurrency(num) {
    const n = Number(num || 0);
    return "₹" + n.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  },

  // -----------------------------------------------------------------
  // Get query param
  // -----------------------------------------------------------------
  getQueryParam(name) {
    const params = new URLSearchParams(window.location.search);
    return params.get(name);
  }
};
