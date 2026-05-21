import { Controller } from "@hotwired/stimulus"
import Tribute from "tributejs"

export default class extends Controller {
  static targets = ["input", "submit"]
  static values = { membersUrl: String }

  connect() {
    this.setupTribute()
    this.boundKeydown = this.handleKeydown.bind(this)
    this.inputTarget.addEventListener("keydown", this.boundKeydown)
    this.autoGrow()
    this.boundInput = this.autoGrow.bind(this)
    this.inputTarget.addEventListener("input", this.boundInput)
  }

  disconnect() {
    if (this.tribute) this.tribute.detach(this.inputTarget)
    this.inputTarget.removeEventListener("keydown", this.boundKeydown)
    this.inputTarget.removeEventListener("input", this.boundInput)
  }

  reset() {
    this.inputTarget.value = ""
    this.autoGrow()
    this.inputTarget.focus()
  }

  handleKeydown(event) {
    if (event.key !== "Enter") return
    if (event.shiftKey) return
    if (this.tribute && this.tribute.isActive) return

    event.preventDefault()
    if (this.inputTarget.value.trim().length === 0) return
    this.element.requestSubmit()
  }

  autoGrow() {
    const el = this.inputTarget
    el.style.height = "auto"
    const max = 160
    el.style.height = Math.min(el.scrollHeight, max) + "px"
  }

  setupTribute() {
    if (!this.membersUrlValue) return

    this.tribute = new Tribute({
      trigger: "@",
      values: (text, cb) => this.fetchMembers(text, cb),
      lookup: "label",
      fillAttr: "handle",
      selectTemplate: item => `@${item.original.handle}`,
      menuItemTemplate: item => `<span class="font-semibold">${item.original.label}</span> <span class="text-gray-500 text-xs">@${item.original.handle}</span>`,
      menuContainer: document.body,
      noMatchTemplate: () => `<span class="text-xs text-gray-500 p-2 block">Sin coincidencias</span>`
    })
    this.tribute.attach(this.inputTarget)
  }

  async fetchMembers(query, callback) {
    try {
      const url = `${this.membersUrlValue}?q=${encodeURIComponent(query || "")}`
      const response = await fetch(url, { headers: { Accept: "application/json" } })
      if (!response.ok) return callback([])
      const data = await response.json()
      callback(data)
    } catch (e) {
      callback([])
    }
  }
}
