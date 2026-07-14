import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="pwa"
// Registra el service worker para habilitar PWA (instalable + offline)
export default class extends Controller {
  connect() {
    if (!("serviceWorker" in navigator)) return;

    const register = () => {
      navigator.serviceWorker.register("/service_worker.js").catch((error) => {
        console.error("[PWA] Service Worker registration failed:", error);
      });
    };

    if (document.readyState === "complete") {
      register();
    } else {
      window.addEventListener("load", register, { once: true });
    }
  }
}
