import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="task-document"
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
      const documents = await response.json();

      this.displayResults(documents);
    } catch (error) {
      console.error("Error searching documents:", error);
    }
  }

  displayResults(documents) {
    if (documents.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="px-4 py-3 text-sm text-gray-500">
          No se encontraron documentos
        </div>
      `;
      this.resultsTarget.classList.remove("hidden");
      return;
    }

    this.resultsTarget.innerHTML = documents.map(doc => `
      <button
        type="button"
        class="w-full px-4 py-2 text-left hover:bg-gray-100 flex items-center gap-2"
        data-action="click->task-document#link"
        data-document-id="${doc.id}"
      >
        <svg class="w-4 h-4 text-gray-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        <div class="flex-1 truncate font-medium text-gray-900">${doc.name}</div>
      </button>
    `).join("");

    this.resultsTarget.classList.remove("hidden");
  }

  async link(event) {
    const button = event.currentTarget;
    const documentId = button.dataset.documentId;

    try {
      const response = await fetch(this.linkUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({ document_id: documentId })
      });

      const data = await response.json();

      if (data.success) {
        this.addLinkedDocument(data.document);
        this.inputTarget.value = "";
        this.resultsTarget.classList.add("hidden");
      } else {
        alert(data.error || "Error al enlazar documento");
      }
    } catch (error) {
      console.error("Error linking document:", error);
      alert("Error al enlazar documento");
    }
  }

  addLinkedDocument(doc) {
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.add("hidden");
    }

    const linkedItem = document.createElement("div");
    linkedItem.className = "flex items-center justify-between gap-2 px-3 py-2 bg-gray-50 border border-gray-200 rounded-lg";
    linkedItem.dataset.documentId = doc.id;
    linkedItem.innerHTML = `
      <a href="${doc.url}" class="flex items-center gap-2 min-w-0 text-sm text-gray-800 hover:text-purple-600 truncate">
        <svg class="w-4 h-4 text-gray-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        <span class="truncate">${doc.name}</span>
      </a>
      <button
        type="button"
        class="flex-shrink-0 text-red-600 hover:text-red-800"
        data-action="click->task-document#unlink"
        data-document-id="${doc.id}"
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
    const documentId = button.dataset.documentId;

    if (!confirm("¿Desenlazar este documento de la tarea?")) {
      return;
    }

    try {
      const url = `${this.unlinkBaseUrlValue}/${documentId}.json`;
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
        alert("Error al desenlazar documento");
      }
    } catch (error) {
      console.error("Error unlinking document:", error);
      alert("Error al desenlazar documento");
    }
  }

  hideResults() {
    setTimeout(() => {
      this.resultsTarget.classList.add("hidden");
    }, 200);
  }
}
