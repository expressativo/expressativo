import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="task-assignee"
export default class extends Controller {
  static targets = ["input", "results", "assignedList"];
  static values = {
    searchUrl: String,
    assignUrl: String,
    unassignBaseUrl: String
  };

  connect() {
    this.timeout = null;
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }

  search() {
    clearTimeout(this.timeout);
    
    const query = this.inputTarget.value.trim();
    
    if (query.length < 2) {
      this.resultsTarget.classList.add("hidden");
      return;
    }

    this.timeout = setTimeout(() => {
      this.performSearch(query);
    }, 300);
  }

  async performSearch(query) {
    try {
      const url = `${this.searchUrlValue}?query=${encodeURIComponent(query)}`;
      const response = await fetch(url);
      const users = await response.json();
      
      this.displayResults(users);
    } catch (error) {
      console.error("Error searching users:", error);
    }
  }

  displayResults(users) {
    if (users.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="px-4 py-3 text-sm text-gray-500">
          No se encontraron usuarios
        </div>
      `;
      this.resultsTarget.classList.remove("hidden");
      return;
    }

    this.resultsTarget.innerHTML = users.map(user => `
      <button
        type="button"
        class="w-full px-4 py-2 text-left hover:bg-gray-100 flex items-center gap-2"
        data-action="click->task-assignee#assign"
        data-user-id="${user.id}"
      >
        <div class="flex-1">
          <div class="font-medium text-gray-900">${user.name}</div>
          <div class="text-sm text-gray-500">${user.email}</div>
        </div>
      </button>
    `).join("");

    this.resultsTarget.classList.remove("hidden");
  }

  async assign(event) {
    const button = event.currentTarget;
    const userId = button.dataset.userId;

    try {
      const response = await fetch(this.assignUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({ user_id: userId })
      });

      const data = await response.json();

      if (data.success) {
        this.addAssignedUser(data.user);
        this.inputTarget.value = "";
        this.resultsTarget.classList.add("hidden");
      } else {
        alert(data.error || "Error al asignar usuario");
      }
    } catch (error) {
      console.error("Error assigning user:", error);
      alert("Error al asignar usuario");
    }
  }

  addAssignedUser(user) {
    const assignedItem = document.createElement("div");
    assignedItem.className = "inline-block px-2 py-1 bg-purple-50 border border-purple-500 rounded-3xl";
    assignedItem.dataset.userId = user.id;
    assignedItem.innerHTML = `
      <div class="flex items-center gap-2 justify-between">
        <div class="font-medium text-gray-900 truncate">${user.name || user.email}</div>
        <button
        type="button"
        class="flex-shrink-0 text-red-600 hover:text-red-800"
        data-action="click->task-assignee#unassign"
        data-user-id="${user.id}"
        >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
        </svg>
        </button>
      </div>
    `;

    this.assignedListTarget.appendChild(assignedItem);
  }

  async unassign(event) {
    const button = event.currentTarget;
    const userId = button.dataset.userId;
    const assignedItem = button.closest("[data-user-id]");

    if (!confirm("¿Desasignar este usuario de la tarea?")) {
      return;
    }

    try {
      const url = `${this.unassignBaseUrlValue}/${userId}`;
      const response = await fetch(url, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        }
      });

      const data = await response.json();

      if (data.success) {
        window.location.reload();
      } else {
        alert("Error al desasignar usuario");
      }
    } catch (error) {
      console.error("Error unassigning user:", error);
      alert("Error al desasignar usuario");
    }
  }

  hideResults() {
    setTimeout(() => {
      this.resultsTarget.classList.add("hidden");
    }, 200);
  }
}
