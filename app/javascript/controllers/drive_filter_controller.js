import { Controller } from "@hotwired/stimulus"

// Client-side fuzzy filter for folder/document cards in the documents view.
export default class extends Controller {
  static targets = ["input", "item"]

  filter() {
    const q = (this.inputTarget.value || "").trim().toLowerCase()
    this.itemTargets.forEach(item => {
      const name = item.dataset.name || ""
      const match = q === "" || name.includes(q)
      item.style.display = match ? "" : "none"
    })
  }
}
