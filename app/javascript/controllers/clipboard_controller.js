import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["source", "button"];
  static values = { url: String };

  copy(event) {
    event.preventDefault();

    const text = this.hasUrlValue && this.urlValue
      ? this.urlValue
      : this.sourceTarget.value;

    navigator.clipboard.writeText(text).then(() => {
      this.showToast("Link copiado al portapapeles");
    }).catch(() => {
      this.showToast("Error al copiar el link", "error");
    });
  }

  showToast(message, type = "success") {
    const container = document.getElementById("toasts");
    if (!container) return;

    const color = type === "success"
      ? "bg-green-600 text-white"
      : "bg-red-600 text-white";

    const toast = document.createElement("div");
    toast.className = `pointer-events-auto w-full max-w-sm overflow-hidden rounded-lg shadow-lg ${color} transition-all duration-300 ease-out`;
    toast.innerHTML = `<div class="p-4 flex items-center gap-3 text-sm font-medium">${message}</div>`;
    container.appendChild(toast);
    setTimeout(() => toast.remove(), 3000);
  }
}
