import { Controller } from "@hotwired/stimulus";

// Toast / Snackbar notifications with auto-dismiss
// Connects to data-controller="toast"
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 4000 }
  };

  connect() {
    // Trigger enter animation on next frame so the browser registers the transition
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        this.element.classList.remove("translate-y-2", "opacity-0");
      });
    });

    // Auto-dismiss after delay
    this.timeout = setTimeout(() => this.close(), this.delayValue);
  }

  disconnect() {
    clearTimeout(this.timeout);
  }

  close() {
    // Trigger exit animation
    this.element.classList.add("translate-y-2", "opacity-0");
    setTimeout(() => this.element.remove(), 300);
  }
}
