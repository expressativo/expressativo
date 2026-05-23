import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

const DISMISS_KEY = "chat_notifier_permission_dismissed"

export default class extends Controller {
  static values = {
    iconUrl: String
  }

  connect() {
    this.originalTitle = document.title
    this.unreadCount = 0

    this._visibilityHandler = () => {
      if (!document.hidden) this.resetTitle()
    }
    document.addEventListener("visibilitychange", this._visibilityHandler)

    this.subscription = consumer.subscriptions.create("NotificationsChannel", {
      received: (data) => this.handle(data),
      connected: () => {
        console.log("[ChatNotifier] Conectado a NotificationsChannel")
      },
      disconnected: () => {
        console.warn("[ChatNotifier] Desconectado de NotificationsChannel")
      }
    })
    this.maybeShowPermissionToast()
    document.addEventListener("click", this._initAudio.bind(this), { once: true })
    console.log("[ChatNotifier] permission:", Notification.permission)
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
    if (this._visibilityHandler) {
      document.removeEventListener("visibilitychange", this._visibilityHandler)
    }
    this.removeToast()
  }

  resetTitle() {
    if (this.unreadCount > 0) {
      document.title = this.originalTitle
      this.unreadCount = 0
    }
  }

  incrementTitle() {
    this.unreadCount += 1
    document.title = `(${this.unreadCount}) ${this.originalTitle}`
  }

  _initAudio() {
    try {
      this.audioCtx = new (window.AudioContext || window.webkitAudioContext)()
    } catch (_) { /* ignore */ }
  }

  playChime() {
    if (!this.audioCtx) return
    try {
      const now = this.audioCtx.currentTime
      const osc = this.audioCtx.createOscillator()
      const gain = this.audioCtx.createGain()

      osc.connect(gain)
      gain.connect(this.audioCtx.destination)

      osc.type = "sine"
      osc.frequency.setValueAtTime(880, now)
      osc.frequency.exponentialRampToValueAtTime(660, now + 0.15)

      gain.gain.setValueAtTime(0.3, now)
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.4)

      osc.start(now)
      osc.stop(now + 0.4)
    } catch (_) { /* ignore */ }
  }

  maybeShowPermissionToast() {
    if (!("Notification" in window)) return
    if (Notification.permission !== "default") return
    if (this.dismissed()) return
    if (document.getElementById("chat-notifier-permission-toast")) return

    const toast = document.createElement("div")
    toast.id = "chat-notifier-permission-toast"
    toast.className = "fixed bottom-4 right-4 z-50 bg-white border border-gray-200 shadow-lg rounded-xl px-4 py-3 flex items-start gap-3 max-w-sm animate-fade-in"
    toast.innerHTML = `
      <div class="flex-shrink-0 w-9 h-9 rounded-full bg-indigo-100 text-indigo-600 flex items-center justify-center">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
        </svg>
      </div>
      <div class="flex-1 min-w-0">
        <p class="text-sm font-semibold text-gray-900">Activa las notificaciones</p>
        <p class="text-xs text-gray-500 mt-0.5">Recibe avisos del navegador cuando llegue un mensaje.</p>
        <div class="mt-2 flex items-center gap-2">
          <button type="button" data-role="enable" class="text-xs font-medium px-3 py-1 rounded-md bg-indigo-600 text-white hover:bg-indigo-700">Activar</button>
          <button type="button" data-role="dismiss" class="text-xs font-medium px-3 py-1 rounded-md text-gray-600 hover:bg-gray-100">Ahora no</button>
        </div>
      </div>
      <button type="button" data-role="close" aria-label="Cerrar" class="flex-shrink-0 text-gray-400 hover:text-gray-600">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
        </svg>
      </button>
    `

    toast.querySelector('[data-role="enable"]').addEventListener("click", () => this.requestPermission())
    toast.querySelector('[data-role="dismiss"]').addEventListener("click", () => { this.persistDismiss(); this.removeToast() })
    toast.querySelector('[data-role="close"]').addEventListener("click", () => { this.persistDismiss(); this.removeToast() })

    document.body.appendChild(toast)
    this.toast = toast
  }

  async requestPermission() {
    try {
      const result = await Notification.requestPermission()
      this.removeToast()
      if (result === "granted") {
        try {
          new Notification("Notificaciones activadas", {
            body: "Te avisaremos cuando llegue un mensaje.",
            icon: this.iconUrlValue || undefined
          })
        } catch (_) { /* ignore */ }
      }
    } catch (_) {
      this.removeToast()
    }
  }

  dismissed() {
    try {
      return sessionStorage.getItem(DISMISS_KEY) === "1"
    } catch (_) {
      return false
    }
  }

  persistDismiss() {
    try { sessionStorage.setItem(DISMISS_KEY, "1") } catch (_) { /* ignore */ }
  }

  removeToast() {
    if (this.toast && this.toast.parentNode) {
      this.toast.parentNode.removeChild(this.toast)
    }
    this.toast = null
  }

  handle(data) {
    if (!data || data.action !== "chat_message") return
    if (this.isViewingMessageable(data)) return

    this.updateSidebar(data)
    this.notify(data)
    this.playChime()
    this.incrementTitle()
  }

  isViewingMessageable(data) {
    if (document.hidden) return false
    const selector = `[data-chat-subscription-messageable-type-value="${data.messageable_type}"][data-chat-subscription-messageable-id-value="${data.messageable_id}"]`
    return Boolean(document.querySelector(selector))
  }

  updateSidebar(data) {
    const key = data.messageable_type === "Channel"
      ? `channel-${data.messageable_id}`
      : `conversation-${data.messageable_id}`
    const item = document.querySelector(`[data-chat-id="${key}"]`)
    if (!item) return

    item.dataset.unread = "true"
    item.classList.remove("text-gray-700", "hover:bg-gray-100")
    item.classList.add("text-gray-900", "font-semibold")

    const badge = item.querySelector("[data-chat-badge]")
    if (!badge) return

    const current = parseInt(badge.textContent, 10)
    const next = Number.isFinite(current) && current > 0 ? current + 1 : 1
    badge.textContent = next > 99 ? "99+" : String(next)
    badge.classList.remove("hidden")
  }

  notify(data) {
    if (!("Notification" in window)) return
    if (Notification.permission !== "granted") return

    const title = data.sender_name
      ? `${data.sender_name} · ${data.title || ""}`.trim()
      : (data.title || "Nuevo mensaje")
    const body = (data.preview || "").trim() || "Tienes un nuevo mensaje"
    const tag = `chat-${data.messageable_type}-${data.messageable_id}`
    const icon = data.sender_avatar_url || this.iconUrlValue || undefined

    try {
      const n = new Notification(title, {
        body,
        tag,
        icon,
        renotify: true
      })
      if (data.url) {
        n.onclick = () => {
          window.focus()
          window.location.href = data.url
          n.close()
        }
      }
    } catch (_) {
      // ignore
    }
  }
}
