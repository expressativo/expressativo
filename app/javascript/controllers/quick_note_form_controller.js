import { Controller } from "@hotwired/stimulus";

// Handles the new-note form: show color picker on focus, submit on Enter
export default class extends Controller {
  static targets = ["input", "controls"];

  connect() {
    this.inputTarget.addEventListener("focus", this.showControls.bind(this));
  }

  showControls() {
    this.controlsTarget.classList.remove("hidden");
    this.controlsTarget.classList.add("flex");
  }

  handleKey(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault();
      const content = this.inputTarget.value.trim();
      if (content.length > 0) {
        this.element.closest("form").requestSubmit();
      }
    }
    if (event.key === "Escape") {
      this.inputTarget.value = "";
      this.inputTarget.blur();
      this.controlsTarget.classList.add("hidden");
      this.controlsTarget.classList.remove("flex");
    }
  }

  selectColor(event) {
    const color = event.currentTarget.dataset.color;
    const spans = this.controlsTarget.querySelectorAll("[data-color]");
    spans.forEach((span) => {
      span.classList.remove("border-gray-500", "scale-110");
      span.classList.add("border-transparent");
    });
    event.currentTarget.classList.remove("border-transparent");
    event.currentTarget.classList.add("border-gray-500", "scale-110");

    // Sync the hidden radio
    const radio = this.element.closest("form").querySelector(`input[type=radio][value="${color}"]`);
    if (radio) radio.checked = true;
  }
}
