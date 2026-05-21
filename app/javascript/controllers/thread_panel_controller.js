import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundEscape = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.boundEscape)
    const firstInput = this.element.querySelector("textarea")
    if (firstInput) firstInput.focus()
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundEscape)
  }

  handleEscape(event) {
    if (event.key !== "Escape") return
    const closeLink = this.element.querySelector("[aria-label='Cerrar hilo']")
    if (closeLink) closeLink.click()
  }
}
