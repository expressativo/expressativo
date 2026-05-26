import { Controller } from "@hotwired/stimulus"

// Toggles between grid and list layout for the Drive-style document list.
// Persists the choice in localStorage so it stays consistent across navigation.
export default class extends Controller {
  static targets = ["gridBtn", "listBtn"]
  static values = { storageKey: { type: String, default: "documents-view" } }

  connect() {
    const saved = localStorage.getItem(this.storageKeyValue) || "grid"
    this.apply(saved)
  }

  grid() { this.apply("grid") }
  list() { this.apply("list") }

  apply(mode) {
    localStorage.setItem(this.storageKeyValue, mode)
    if (this.hasGridBtnTarget) this.gridBtnTarget.dataset.active = (mode === "grid")
    if (this.hasListBtnTarget) this.listBtnTarget.dataset.active = (mode === "list")

    document.querySelectorAll("[data-drive-filter-target='item']").forEach(item => {
      item.dataset.viewMode = mode
    })

    document.querySelectorAll(".drive-document, .drive-folder").forEach(card => {
      if (mode === "list") {
        card.classList.add("drive-as-list")
      } else {
        card.classList.remove("drive-as-list")
      }
    })

    document.querySelectorAll("[data-drive-grid]").forEach(grid => {
      if (mode === "list") {
        grid.dataset.previousClass = grid.className
        grid.className = "flex flex-col gap-1.5 mb-6"
      } else if (grid.dataset.previousClass) {
        grid.className = grid.dataset.previousClass
      }
    })
  }
}
