import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { markReadUrl: String }

  connect() {
    this.scrollToBottom(false)
    this.boundOnStream = this.onStream.bind(this)
    this.element.addEventListener("turbo:before-stream-render", this.boundOnStream)
    this.scheduleMarkRead()
  }

  disconnect() {
    this.element.removeEventListener("turbo:before-stream-render", this.boundOnStream)
    if (this.markReadTimer) clearTimeout(this.markReadTimer)
  }

  onStream() {
    requestAnimationFrame(() => this.scrollToBottom(this.isNearBottom()))
  }

  isNearBottom() {
    const threshold = 80
    return this.element.scrollHeight - this.element.scrollTop - this.element.clientHeight < threshold
  }

  scrollToBottom(onlyIfNear) {
    if (onlyIfNear && !this.isNearBottom()) return
    this.element.scrollTop = this.element.scrollHeight
  }

  scheduleMarkRead() {
    if (!this.markReadUrlValue) return
    this.markReadTimer = setTimeout(() => this.markRead(), 800)
  }

  async markRead() {
    try {
      await fetch(this.markReadUrlValue, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
          Accept: "application/json"
        }
      })
    } catch (_) {}
  }
}
