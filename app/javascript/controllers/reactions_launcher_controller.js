import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundClick = this.handleClick.bind(this)
    this.boundOutside = this.handleOutside.bind(this)
    this.boundEscape = this.handleEscape.bind(this)
    this.element.addEventListener("click", this.boundClick)
    document.addEventListener("click", this.boundOutside, true)
    document.addEventListener("keydown", this.boundEscape)
  }

  disconnect() {
    this.element.removeEventListener("click", this.boundClick)
    document.removeEventListener("click", this.boundOutside, true)
    document.removeEventListener("keydown", this.boundEscape)
    if (this.picker) {
      this.picker.remove()
      this.picker = null
    }
  }

  handleClick(event) {
    const trigger = event.target.closest("[data-reaction-trigger]")
    if (!trigger) return
    event.preventDefault()
    event.stopPropagation()
    this.openPicker(trigger)
  }

  handleOutside(event) {
    if (!this.picker || this.picker.hidden) return
    if (this.picker.contains(event.target)) return
    if (event.target.closest("[data-reaction-trigger]")) return
    this.closePicker()
  }

  handleEscape(event) {
    if (event.key === "Escape") this.closePicker()
  }

  async openPicker(trigger) {
    await this.ensurePickerElement()
    this.actionUrl = trigger.dataset.actionUrl
    this.activeMessageId = trigger.dataset.messageId

    const rect = trigger.getBoundingClientRect()
    const pickerHeight = 380
    const pickerWidth = 350
    const margin = 8

    let top = rect.bottom + margin
    if (top + pickerHeight > window.innerHeight) {
      top = Math.max(margin, rect.top - pickerHeight - margin)
    }
    let left = rect.right - pickerWidth
    if (left < margin) left = margin
    if (left + pickerWidth > window.innerWidth) left = window.innerWidth - pickerWidth - margin

    this.picker.style.top = `${top}px`
    this.picker.style.left = `${left}px`
    this.picker.hidden = false
  }

  closePicker() {
    if (this.picker) this.picker.hidden = true
    this.activeMessageId = null
    this.actionUrl = null
  }

  async ensurePickerElement() {
    if (this.picker) return
    if (!window.customElements.get("emoji-picker")) {
      await import("emoji-picker-element")
    }
    const wrap = document.createElement("div")
    wrap.className = "fixed z-[60] shadow-xl rounded-lg overflow-hidden"
    wrap.style.position = "fixed"
    wrap.hidden = true

    const picker = document.createElement("emoji-picker")
    picker.classList.add("light")
    wrap.appendChild(picker)
    document.body.appendChild(wrap)

    picker.addEventListener("emoji-click", (e) => this.onSelect(e.detail.unicode))
    this.picker = wrap
  }

  async onSelect(emoji) {
    if (!this.actionUrl) return
    const url = this.actionUrl
    this.closePicker()

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "X-CSRF-Token": token,
          "Content-Type": "application/x-www-form-urlencoded",
          Accept: "text/vnd.turbo-stream.html"
        },
        body: `emoji=${encodeURIComponent(emoji)}`
      })
      if (!response.ok) return
      const html = await response.text()
      if (html.trim().length) window.Turbo.renderStreamMessage(html)
    } catch (_) {}
  }
}
