import { Controller } from "@hotwired/stimulus";
import consumer from "channels/consumer";

// Exporta un documento rich_text a PDF en background.
//
// Flujo:
//   1. El usuario clickea "Exportar a PDF".
//   2. POST a export_pdf_document_path -> el server encola DocumentPdfExportJob.
//   3. Se muestra un overlay centrado con spinner ("Exportando a PDF...").
//   4. El job, al terminar, hace broadcast por NotificationsChannel.
//   5. Este controller recibe el evento, descarga el PDF y oculta el overlay.
//
// Conecta a data-controller="pdf-export"
export default class extends Controller {
  static values = {
    url: String,
    documentId: String
  };
  static targets = ["overlay"];

  // Tiempo máximo de espera del broadcast antes de cancelar con error.
  static SAFETY_TIMEOUT_MS = 90_000;

  connect() {
    this.subscription = null;
    this.busy = false;
    this.safetyTimer = null;
  }

  disconnect() {
    this.cleanup();
  }

  async start(event) {
    event.preventDefault();
    event.stopPropagation();
    if (this.busy) return;

    this.closeDropdown();
    this.busy = true;
    this.showOverlay();
    this.subscribe();
    this.armSafetyTimer();

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this.csrfToken(),
          "Accept": "application/json"
        }
      });

      // 202 Accepted = job encolado. El resto lo maneja el canal.
      if (!response.ok && response.status !== 202) {
        throw new Error(`HTTP ${response.status}`);
      }
    } catch (_err) {
      this.reset("No se pudo iniciar la exportación.", "alert");
    }
  }

  subscribe() {
    if (this.subscription) return;
    this.subscription = consumer.subscriptions.create("NotificationsChannel", {
      received: (data) => this.onReceive(data)
    });
  }

  unsubscribe() {
    if (this.subscription) {
      this.subscription.unsubscribe();
      this.subscription = null;
    }
  }

  onReceive(data) {
    if (!data) return;
    if (String(data.document_id) !== this.documentIdValue) return;

    if (data.action === "pdf_ready") {
      this.hideOverlay();
      this.download(data.url, data.filename);
      this.cleanup();
      this.busy = false;
      this.showToast("PDF generado correctamente.", "success");
    } else if (data.action === "pdf_error") {
      this.reset(data.message || "No se pudo generar el PDF.", "alert");
    }
  }

  showOverlay() {
    this.overlayTarget.classList.remove("hidden");
  }

  hideOverlay() {
    this.overlayTarget.classList.add("hidden");
  }

  download(url, filename) {
    const link = document.createElement("a");
    link.href = url;
    link.download = filename || "";
    link.style.display = "none";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  reset(message, type) {
    this.hideOverlay();
    this.cleanup();
    this.busy = false;
    this.showToast(message, type);
  }

  cleanup() {
    this.clearSafetyTimer();
    this.unsubscribe();
  }

  armSafetyTimer() {
    this.clearSafetyTimer();
    this.safetyTimer = setTimeout(() => {
      this.reset("La exportación está tardando demasiado. Intentá nuevamente.", "alert");
    }, this.constructor.SAFETY_TIMEOUT_MS);
  }

  clearSafetyTimer() {
    if (this.safetyTimer) {
      clearTimeout(this.safetyTimer);
      this.safetyTimer = null;
    }
  }

  closeDropdown() {
    const dropdownEl = this.element.closest('[data-controller~="dropdown"]');
    if (!dropdownEl) return;
    const ctrl = this.application.getControllerForElementAndIdentifier(dropdownEl, "dropdown");
    ctrl?.close?.();
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.content : "";
  }

  showToast(message, type = "notice") {
    const container = document.getElementById("toasts");
    if (!container) {
      window.alert(message);
      return;
    }

    const icons = {
      success: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>',
      alert: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>',
      notice: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>'
    };
    const typeClasses = {
      success: "bg-green-600 text-white",
      alert: "bg-red-600 text-white",
      notice: "bg-blue-600 text-white"
    };

    const toast = document.createElement("div");
    toast.setAttribute("data-controller", "toast");
    toast.setAttribute("data-toast-delay-value", "4000");
    toast.className = `pointer-events-auto w-full max-w-sm overflow-hidden rounded-lg shadow-lg ring-1 ring-black ring-opacity-5 ${typeClasses[type] || typeClasses.notice} transition-all duration-300 ease-out translate-y-2 opacity-0`;
    toast.innerHTML = `
      <div class="p-4">
        <div class="flex items-start gap-3">
          <div class="shrink-0 opacity-90">
            <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">${icons[type] || icons.notice}</svg>
          </div>
          <div class="flex-1 text-sm font-medium pt-0.5">${this.escape(message)}</div>
          <button type="button" class="inline-flex shrink-0 items-center justify-center rounded-md opacity-75 hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 -mr-1 -mt-1 p-1" data-action="click->toast#close">
            <svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M18 6 6 18M6 6l12 12"/>
            </svg>
          </button>
        </div>
      </div>
    `;
    container.appendChild(toast);
  }

  escape(text) {
    const div = document.createElement("div");
    div.textContent = text == null ? "" : String(text);
    return div.innerHTML;
  }
}
