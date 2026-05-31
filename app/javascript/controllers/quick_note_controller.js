import { Controller } from "@hotwired/stimulus";

// Handles inline edit/save on existing notes
export default class extends Controller {
  static targets = ["view", "form"];

  startEdit() {
    this.viewTarget.classList.add("hidden");
    this.formTarget.classList.remove("hidden");
    const textarea = this.formTarget.querySelector("textarea");
    if (textarea) {
      textarea.focus();
      textarea.setSelectionRange(textarea.value.length, textarea.value.length);
    }
  }

  cancelEdit() {
    this.formTarget.classList.add("hidden");
    this.viewTarget.classList.remove("hidden");
  }

  submitEdit() {
    this.formTarget.requestSubmit();
  }

  handleKey(event) {
    if (event.key === "Escape") {
      this.cancelEdit();
    } else if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault();
      this.submitEdit();
    }
  }

  changeColor(event) {
    const color = event.target.value;
    const colorClasses = {
      yellow: ["bg-amber-50", "border-amber-200"],
      pink: ["bg-pink-50", "border-pink-200"],
      blue: ["bg-blue-50", "border-blue-200"],
      green: ["bg-green-50", "border-green-200"],
    };
    const dotClasses = {
      yellow: "bg-amber-400",
      pink: "bg-pink-400",
      blue: "bg-blue-400",
      green: "bg-green-400",
    };

    // Update card background
    Object.values(colorClasses).flat().forEach((cls) => this.element.classList.remove(cls));
    colorClasses[color]?.forEach((cls) => this.element.classList.add(cls));

    // Update dot color
    const dot = this.viewTarget.querySelector(".rounded-full.w-2");
    if (dot) {
      Object.values(dotClasses).forEach((cls) => dot.classList.remove(cls));
      dot.classList.add(dotClasses[color]);
    }
  }
}
