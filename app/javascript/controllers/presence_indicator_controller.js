import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["dot"]
  static values = { projectId: Number }

  connect() {
    if (!this.projectIdValue) return

    this.subscription = consumer.subscriptions.create(
      { channel: "PresenceChannel", project_id: this.projectIdValue },
      {
        connected: () => this.startHeartbeat(),
        disconnected: () => this.stopHeartbeat(),
        received: (data) => this.applyStatus(data)
      }
    )
  }

  disconnect() {
    this.stopHeartbeat()
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }

  startHeartbeat() {
    if (this.heartbeat) return
    this.heartbeat = setInterval(() => {
      if (this.subscription) this.subscription.perform("heartbeat")
    }, 25_000)
  }

  stopHeartbeat() {
    if (this.heartbeat) {
      clearInterval(this.heartbeat)
      this.heartbeat = null
    }
  }

  applyStatus(data) {
    if (!data || !data.user_id) return

    this.dotTargets.forEach((dot) => {
      if (Number(dot.dataset.userId) !== Number(data.user_id)) return
      if (data.status === "online") {
        dot.classList.remove("bg-gray-300")
        dot.classList.add("bg-green-500")
        dot.title = "En línea"
      } else {
        dot.classList.remove("bg-green-500")
        dot.classList.add("bg-gray-300")
        dot.title = "Desconectado"
      }
    })
  }
}
