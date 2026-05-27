import { Controller } from "@hotwired/stimulus";

// Handles Web Push subscription and unsubscription.
// Expects a meta tag with name="vapid-public-key" in the page.
export default class extends Controller {
  static targets = [
    "track",
    "knob",
    "settingsRow",
    "settingsIconOn",
    "settingsIconOff",
    "settingsText"
  ];
  static values = {
    vapidKey: { type: String, default: "" }
  };

  TOAST_ID = "push-permission-toast";
  DISMISS_KEY = "push_permission_dismissed";

  connect() {
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      this.hideSettings();
      return;
    }

    const currentUserMeta = document.querySelector('meta[name="current-user-id"]');
    if (!currentUserMeta) {
      this.hideSettings();
      return;
    }

    const meta = document.querySelector('meta[name="vapid-public-key"]');
    if (meta) {
      this.vapidKeyValue = meta.content;
    }

    this.updateSettingsVisibility();

    this.registerServiceWorker().then(() => {
      this.updateSettingsVisibility();
      this.updateToggleSwitch();
      this.maybeShowToast();
    });

    this._permissionHandler = (event) => {
      this.handlePermissionGranted();
    };
    document.addEventListener("push-permission-granted", this._permissionHandler);
  }

  disconnect() {
    this.removeToast();
    if (this._permissionHandler) {
      document.removeEventListener("push-permission-granted", this._permissionHandler);
    }
  }

  async handlePermissionGranted() {
    if (!this.vapidKeyValue) return;
    if (!this.registration) return;

    await this.subscribe();
    await this.updateToggleSwitch();
    this.showGrantedFeedback();
  }

  async registerServiceWorker() {
    try {
      this.registration = await navigator.serviceWorker.register("/service_worker.js");
    } catch (error) {
      console.error("[PushNotifications] Service Worker registration failed:", error);
    }
  }

  maybeShowToast() {
    if (!this.vapidKeyValue) return;
    if (Notification.permission !== "default") return;
    if (this.dismissed()) return;
    if (document.getElementById(this.TOAST_ID)) return;
    if (document.getElementById("chat-notifier-permission-toast")) return;

    const toast = document.createElement("div");
    toast.id = this.TOAST_ID;
    toast.className = "fixed bottom-4 right-4 z-50 bg-white border border-gray-200 shadow-lg rounded-xl px-4 py-3 flex items-start gap-3 max-w-sm animate-fade-in";
    toast.innerHTML = `
      <div class="flex-shrink-0 w-9 h-9 rounded-full bg-purple-100 text-purple-600 flex items-center justify-center">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
        </svg>
      </div>
      <div class="flex-1 min-w-0">
        <p class="text-sm font-semibold text-gray-900">Activa las notificaciones</p>
        <p class="text-xs text-gray-500 mt-0.5">Recibe avisos del navegador cuando llegue un mensaje.</p>
        <div class="mt-2 flex items-center gap-2">
          <button type="button" data-role="enable" class="text-xs font-medium px-3 py-1.5 rounded-md bg-purple-600 text-white hover:bg-purple-700 transition-colors">Activar</button>
          <button type="button" data-role="dismiss" class="text-xs font-medium px-3 py-1.5 rounded-md text-gray-600 hover:bg-gray-100 transition-colors">Ahora no</button>
        </div>
      </div>
      <button type="button" data-role="close" aria-label="Cerrar" class="flex-shrink-0 text-gray-400 hover:text-gray-600 transition-colors">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
        </svg>
      </button>
    `;

    toast.querySelector('[data-role="enable"]').addEventListener("click", () => this.requestPermission());
    toast.querySelector('[data-role="dismiss"]').addEventListener("click", () => { this.persistDismiss(); this.removeToast(); });
    toast.querySelector('[data-role="close"]').addEventListener("click", () => { this.persistDismiss(); this.removeToast(); });

    document.body.appendChild(toast);
    this.toast = toast;
  }

  async requestPermission() {
    try {
      const result = await Notification.requestPermission();
      this.removeToast();

      if (result === "granted") {
        await this.subscribe();
        await this.updateToggleSwitch();
        this.showGrantedFeedback();
      }
    } catch (_) {
      this.removeToast();
    }
  }

  showGrantedFeedback() {
    const feedback = document.createElement("div");
    feedback.className = "fixed bottom-4 right-4 z-50 bg-green-600 text-white text-sm font-medium px-4 py-2.5 rounded-lg shadow-lg animate-fade-in";
    feedback.textContent = "Notificaciones activadas";
    document.body.appendChild(feedback);
    setTimeout(() => {
      if (feedback.parentNode) feedback.parentNode.removeChild(feedback);
    }, 2500);
  }

  async toggle(event) {
    event.stopPropagation();

    if (!this.registration) return;

    const subscription = await this.registration.pushManager.getSubscription();

    if (subscription) {
      await this.unsubscribe(subscription);
    } else {
      if (Notification.permission === "default") {
        const result = await Notification.requestPermission();
        if (result !== "granted") return;
      }
      await this.subscribe();
    }

    await this.updateToggleSwitch();
  }

  async subscribe() {
    if (!this.vapidKeyValue) return;
    if (!this.registration) return;

    try {
      const subscription = await this.registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(this.vapidKeyValue)
      });

      await this.saveSubscription(subscription);
    } catch (error) {
      console.error("[PushNotifications] Subscription failed:", error);
    }
  }

  async unsubscribe(subscription) {
    try {
      await subscription.unsubscribe();
      await this.deleteSubscription(subscription.endpoint);
    } catch (error) {
      console.error("[PushNotifications] Unsubscribe failed:", error);
    }
  }

  async saveSubscription(subscription) {
    const response = await fetch("/push_subscription", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify({
        push_subscription: {
          endpoint: subscription.endpoint,
          p256dh: btoa(String.fromCharCode(...new Uint8Array(subscription.getKey("p256dh")))),
          auth: btoa(String.fromCharCode(...new Uint8Array(subscription.getKey("auth"))))
        }
      })
    });

    if (!response.ok) {
      console.error("[PushNotifications] Failed to save subscription on server, status:", response.status);
    }
  }

  async deleteSubscription(endpoint) {
    const response = await fetch("/push_subscription", {
      method: "DELETE",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify({ endpoint })
    });

    if (!response.ok) {
      console.error("[PushNotifications] Failed to delete subscription on server");
    }
  }

  updateSettingsVisibility() {
    if (!this.hasSettingsRowTarget) return;

    const hasKey = !!this.vapidKeyValue;
    if (hasKey) {
      this.settingsRowTarget.classList.remove("hidden");
    } else {
      this.settingsRowTarget.classList.add("hidden");
    }
  }

  async updateToggleSwitch() {
    if (!this.registration) return;
    if (!this.hasTrackTarget || !this.hasKnobTarget) return;

    const subscription = await this.registration.pushManager.getSubscription();
    const isSubscribed = !!subscription;

    if (isSubscribed) {
      this.trackTarget.classList.remove("bg-gray-200");
      this.trackTarget.classList.add("bg-purple-600");
      this.knobTarget.classList.remove("translate-x-0");
      this.knobTarget.classList.add("translate-x-5");
    } else {
      this.trackTarget.classList.remove("bg-purple-600");
      this.trackTarget.classList.add("bg-gray-200");
      this.knobTarget.classList.remove("translate-x-5");
      this.knobTarget.classList.add("translate-x-0");
    }

    if (this.hasSettingsIconOnTarget && this.hasSettingsIconOffTarget) {
      if (isSubscribed) {
        this.settingsIconOnTarget.classList.remove("hidden");
        this.settingsIconOffTarget.classList.add("hidden");
      } else {
        this.settingsIconOnTarget.classList.add("hidden");
        this.settingsIconOffTarget.classList.remove("hidden");
      }
    }

    if (this.hasSettingsTextTarget) {
      this.settingsTextTarget.textContent = isSubscribed
        ? "Las notificaciones push están activadas"
        : "Recibí alertas incluso cuando no estés en la app";
    }
  }

  dismissed() {
    try {
      return localStorage.getItem(this.DISMISS_KEY) === "1";
    } catch (_) {
      return false;
    }
  }

  persistDismiss() {
    try { localStorage.setItem(this.DISMISS_KEY, "1"); } catch (_) { /* ignore */ }
  }

  removeToast() {
    if (this.toast && this.toast.parentNode) {
      this.toast.parentNode.removeChild(this.toast);
    }
    this.toast = null;
  }

  hideSettings() {
    if (this.hasSettingsRowTarget) {
      this.settingsRowTarget.classList.add("hidden");
    }
    this.removeToast();
  }

  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
    const base64 = (base64String + padding).replace(/\-/g, "+").replace(/_/g, "/");
    const rawData = window.atob(base64);
    return Uint8Array.from([...rawData].map((char) => char.charCodeAt(0)));
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || "";
  }
}
