import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["badge"]
  static values = { url: String }

  connect() {
    this.updateCount()
    this.subscription = consumer.subscriptions.create("NotificationsChannel", {
      received: (data) => this.onReceive(data)
    })
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }

  onReceive(data) {
    if (!data) return

    if (typeof data.unread_count === "number") {
      this.displayCount(data.unread_count)
    } else {
      this.updateCount()
    }
  }

  async updateCount() {
    if (!this.urlValue) return

    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      if (!response.ok) return
      const data = await response.json()
      this.displayCount(data.count)
    } catch (_) {
      // ignore
    }
  }

  displayCount(count) {
    if (count > 0) {
      this.badgeTarget.textContent = count > 99 ? "99+" : count
      this.badgeTarget.classList.remove("hidden")
    } else {
      this.badgeTarget.classList.add("hidden")
    }
  }
}
