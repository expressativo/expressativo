import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static values = {
    messageableType: String,
    messageableId: Number
  }

  connect() {
    if (!this.messageableTypeValue || !this.messageableIdValue) return

    this.subscription = consumer.subscriptions.create(
      {
        channel: "ChatChannel",
        messageable_type: this.messageableTypeValue,
        messageable_id: this.messageableIdValue
      },
      {
        received: (data) => this.received(data)
      }
    )
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }

  get currentUserId() {
    const meta = document.querySelector('meta[name="current-user-id"]')
    return meta ? Number(meta.content) : null
  }

  received(data) {
    if (!data || !data.html) return

    const existing = document.getElementById(`message_${data.message_id}`)

    if (data.action === "create" && Number(data.user_id) === this.currentUserId && existing) {
      return
    }

    if (data.scope === "thread") {
      this.handleThreadMessage(data, existing)
      return
    }

    const insert = () => {
      if (existing) {
        existing.outerHTML = data.html
      } else {
        this.element.insertAdjacentHTML("beforeend", data.html)
      }
      this.element.scrollTop = this.element.scrollHeight
      window.dispatchEvent(new CustomEvent("chat:dom-updated"))
    }
    requestAnimationFrame(insert)
  }

  handleThreadMessage(data, existing) {
    const repliesContainer = document.getElementById(`replies_message_${data.thread_root_id}`)
    if (!repliesContainer) return

    const insert = () => {
      if (existing) {
        existing.outerHTML = data.html
      } else {
        repliesContainer.insertAdjacentHTML("beforeend", data.html)
      }
      repliesContainer.scrollTop = repliesContainer.scrollHeight
      window.dispatchEvent(new CustomEvent("chat:dom-updated"))
    }
    requestAnimationFrame(insert)
  }
}
