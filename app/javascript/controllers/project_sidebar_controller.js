import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["label", "toggleIcon"]
  static values = { storageKey: { type: String, default: "project_sidebar_collapsed" } }

  connect() {
    this.collapsed = localStorage.getItem(this.storageKeyValue) === "true"
    this.apply()
  }

  toggle() {
    this.collapsed = !this.collapsed
    localStorage.setItem(this.storageKeyValue, this.collapsed)
    this.apply()
  }

  apply() {
    this.element.dataset.collapsed = this.collapsed
    this.labelTargets.forEach(el => el.classList.toggle("hidden", this.collapsed))
    if (this.hasToggleIconTarget) {
      this.toggleIconTarget.innerHTML = this.collapsed
        ? '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 5l7 7-7 7M5 5l7 7-7 7"/>'
        : '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 19l-7-7 7-7m8 14l-7-7 7-7"/>'
    }
  }
}
