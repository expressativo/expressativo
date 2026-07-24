import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="document-task"
export default class extends Controller {
  static targets = ["input", "results", "linkedList", "emptyState"];
  static values = {
    searchUrl: String,
    linkUrl: String,
    unlinkBaseUrl: String
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
      const tasks = await response.json();

      this.displayResults(tasks);
    } catch (error) {
      console.error("Error searching tasks:", error);
    }
  }

  displayResults(tasks) {
    if (tasks.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="px-4 py-3 text-sm text-gray-500">
          No se encontraron tareas
        </div>
      `;
      this.resultsTarget.classList.remove("hidden");
      return;
    }

    this.resultsTarget.innerHTML = tasks.map(task => `
      <button
        type="button"
        class="w-full px-4 py-2 text-left hover:bg-gray-100 flex items-center gap-2"
        data-action="click->document-task#link"
        data-task-id="${task.id}"
      >
        <svg class="w-4 h-4 text-gray-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"/>
        </svg>
        <div class="flex-1 min-w-0">
          <div class="truncate font-medium text-gray-900">${task.title}</div>
          <div class="truncate text-xs text-gray-500">${task.todo_name}</div>
        </div>
      </button>
    `).join("");

    this.resultsTarget.classList.remove("hidden");
  }

  async link(event) {
    const button = event.currentTarget;
    const taskId = button.dataset.taskId;

    try {
      const response = await fetch(this.linkUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({ task_id: taskId })
      });

      const data = await response.json();

      if (data.success) {
        this.addLinkedTask(data.task);
        this.inputTarget.value = "";
        this.resultsTarget.classList.add("hidden");
      } else {
        alert(data.error || "Error al enlazar tarea");
      }
    } catch (error) {
      console.error("Error linking task:", error);
      alert("Error al enlazar tarea");
    }
  }

  addLinkedTask(task) {
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.add("hidden");
    }

    const linkedItem = document.createElement("div");
    linkedItem.className = "flex items-center justify-between gap-2 px-3 py-2 bg-gray-50 border border-gray-200 rounded-lg";
    linkedItem.dataset.taskId = task.id;
    linkedItem.innerHTML = `
      <a href="${task.url}" class="flex items-center gap-2 min-w-0 text-sm text-gray-800 hover:text-purple-600 truncate">
        <svg class="w-4 h-4 text-gray-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"/>
        </svg>
        <span class="truncate">${task.title}</span>
      </a>
      <button
        type="button"
        class="flex-shrink-0 text-red-600 hover:text-red-800"
        data-action="click->document-task#unlink"
        data-task-id="${task.id}"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
        </svg>
      </button>
    `;

    this.linkedListTarget.appendChild(linkedItem);
  }

  async unlink(event) {
    const button = event.currentTarget;
    const taskId = button.dataset.taskId;

    if (!confirm("¿Desenlazar esta tarea de este documento?")) {
      return;
    }

    try {
      const url = `${this.unlinkBaseUrlValue}/${taskId}.json`;
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
        alert("Error al desenlazar tarea");
      }
    } catch (error) {
      console.error("Error unlinking task:", error);
      alert("Error al desenlazar tarea");
    }
  }

  hideResults() {
    setTimeout(() => {
      this.resultsTarget.classList.add("hidden");
    }, 200);
  }
}
