import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { markReadUrl: String, olderUrl: String }

  connect() {
    this.scrollToBottom(false)
    this.boundOnStream = this.onStream.bind(this)
    this.element.addEventListener("turbo:before-stream-render", this.boundOnStream)
    this.scheduleMarkRead()

    this.loadingOlder = false
    this.noMoreOlder = false
    this.boundOnScroll = this.onScroll.bind(this)
    if (this.hasOlderUrlValue) {
      this.element.addEventListener("scroll", this.boundOnScroll, { passive: true })
    }
  }

  disconnect() {
    this.element.removeEventListener("turbo:before-stream-render", this.boundOnStream)
    if (this.boundOnScroll) this.element.removeEventListener("scroll", this.boundOnScroll)
    if (this.markReadTimer) clearTimeout(this.markReadTimer)
  }

  onStream() {
    if (this.loadingOlder) return
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

  onScroll() {
    if (this.loadingOlder || this.noMoreOlder) return
    if (this.element.scrollTop > 120) return
    this.loadOlder()
  }

  async loadOlder() {
    const firstMessage = this.element.querySelector("[data-message-id]")
    if (!firstMessage) {
      this.noMoreOlder = true
      return
    }
    const beforeId = firstMessage.dataset.messageId
    this.loadingOlder = true
    this.showLoadingIndicator()

    const previousHeight = this.element.scrollHeight
    const previousTop = this.element.scrollTop

    try {
      const url = `${this.olderUrlValue}?before_id=${encodeURIComponent(beforeId)}`
      const response = await fetch(url, {
        headers: { Accept: "text/vnd.turbo-stream.html" }
      })
      if (!response.ok) {
        this.noMoreOlder = true
        return
      }
      const hasMore = response.headers.get("X-Has-More")
      if (hasMore === "false") this.noMoreOlder = true

      const html = await response.text()
      if (html.trim().length === 0) {
        this.noMoreOlder = true
        return
      }

      window.Turbo.renderStreamMessage(html)

      requestAnimationFrame(() => {
        const newHeight = this.element.scrollHeight
        this.element.scrollTop = previousTop + (newHeight - previousHeight)
        window.dispatchEvent(new CustomEvent("chat:dom-updated"))
      })
    } catch (_) {
      this.noMoreOlder = true
    } finally {
      this.hideLoadingIndicator()
      this.loadingOlder = false
    }
  }

  showLoadingIndicator() {
    if (this.loadingNode) return
    this.loadingNode = document.createElement("div")
    this.loadingNode.className = "text-center text-xs text-gray-400 py-2"
    this.loadingNode.textContent = "Cargando…"
    this.element.insertBefore(this.loadingNode, this.element.firstChild)
  }

  hideLoadingIndicator() {
    if (this.loadingNode) {
      this.loadingNode.remove()
      this.loadingNode = null
    }
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
