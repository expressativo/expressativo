import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="notification-badge"
export default class extends Controller {
  static targets = ["badge"];
  static values = {
    url: String
  };

  connect() {
    this.updateCount();
    // Actualizar cada 30 segundos
    this.interval = setInterval(() => this.updateCount(), 30000);
  }

  disconnect() {
    if (this.interval) {
      clearInterval(this.interval);
    }
  }

  async updateCount() {
    try {
      const response = await fetch(this.urlValue);
      if (response.ok) {
        const data = await response.json();
        this.displayCount(data.count);
      }
    } catch (error) {
      console.error('Error fetching notification count:', error);
    }
  }

  displayCount(count) {
    if (count > 0) {
      this.badgeTarget.textContent = count > 99 ? '99+' : count;
      this.badgeTarget.classList.remove('hidden');
    } else {
      this.badgeTarget.classList.add('hidden');
    }
  }
}
