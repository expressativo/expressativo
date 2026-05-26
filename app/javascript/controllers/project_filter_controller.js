import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="project-filter"
export default class extends Controller {
  static targets = ["input", "item", "counter", "empty", "list"];

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase();
    let visible = 0;

    this.itemTargets.forEach((item) => {
      const haystack = item.dataset.projectName || "";
      const matches = query === "" || haystack.includes(query);
      item.classList.toggle("hidden", !matches);
      if (matches) visible += 1;
    });

    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("hidden", visible > 0);
    }
    if (this.hasListTarget) {
      this.listTarget.classList.toggle("hidden", visible === 0);
    }
    if (this.hasCounterTarget) {
      const word = visible === 1 ? "proyecto" : "proyectos";
      this.counterTarget.textContent = `${visible} ${word}`;
    }
  }
}
