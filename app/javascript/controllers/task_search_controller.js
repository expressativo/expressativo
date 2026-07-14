import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="task-search"
export default class extends Controller {
  static targets = ["input", "card"];

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase();

    this.cardTargets.forEach(card => {
      const title = (card.dataset.taskTitle || "").toLowerCase();
      card.classList.toggle("hidden", query !== "" && !title.includes(query));
    });

    this.element.querySelectorAll(".column-draggable").forEach(column => {
      if (query === "") {
        column.classList.remove("hidden");
        return;
      }
      const hasVisibleCards = this.cardTargets.some(card =>
        column.contains(card) && !card.classList.contains("hidden")
      );
      column.classList.toggle("hidden", !hasVisibleCards);
    });
  }
}
