import { Controller } from "@hotwired/stimulus";
import Tribute from "tributejs";

// Connects to data-controller="trix-mentions"
export default class extends Controller {
  static values = {
    projectId: Number,
    todoId: Number,
    taskId: Number
  };

  connect() {
    console.log("Trix Mentions Controller connected");
    
    // Buscar el elemento trix-editor
    this.trixEditor = this.element.querySelector("trix-editor");
    
    console.log("Trix editor found:", this.trixEditor);
    
    if (this.trixEditor) {
      // Si ya está inicializado
      if (this.trixEditor.editor) {
        console.log("Trix already initialized, setting up Tribute");
        this.initializeTribute();
      } else {
        // Esperar a que Trix esté completamente cargado
        console.log("Waiting for trix-initialize event");
        this.trixEditor.addEventListener("trix-initialize", () => {
          console.log("Trix initialized, setting up Tribute");
          this.initializeTribute();
        }, { once: true });
      }
    } else {
      console.error("Trix editor not found in element");
    }
  }

  disconnect() {
    if (this.tribute && this.trixEditor) {
      this.tribute.detach(this.trixEditor);
    }
  }

  initializeTribute() {
    console.log("Initializing Tribute.js");
    console.log("Project ID:", this.projectIdValue);
    console.log("Todo ID:", this.todoIdValue);
    console.log("Task ID:", this.taskIdValue);
    
    this.tribute = new Tribute({
      trigger: "@",
      values: async (text, callback) => {
        console.log("Tribute searching for:", text);
        await this.searchUsers(text, callback);
      },
      selectTemplate: (item) => {
        console.log("Selected user:", item.original.name);
        return `@${item.original.name}`;
      },
      menuItemTemplate: (item) => {
        return `
          <div class="flex items-center gap-2 p-2">
            <div class="w-8 h-8 rounded-full bg-indigo-600 flex items-center justify-center text-white text-sm font-semibold">
              ${item.original.initials}
            </div>
            <div>
              <div class="font-medium text-sm text-gray-900">${item.original.name}</div>
              <div class="text-xs text-gray-500">${item.original.email}</div>
            </div>
          </div>
        `;
      },
      noMatchTemplate: () => {
        return '<span class="text-gray-500 text-sm p-2">No se encontraron usuarios</span>';
      },
      lookup: "name",
      fillAttr: "name",
      allowSpaces: true,
      menuShowMinLength: 1
    });

    console.log("Attaching Tribute to Trix editor");
    this.tribute.attach(this.trixEditor);
    console.log("Tribute attached successfully");
  }

  async searchUsers(query, callback) {
    console.log("searchUsers called with query:", query);
    
    if (!query || query.length < 1) {
      console.log("Query too short, returning empty");
      callback([]);
      return;
    }

    const url = `/projects/${this.projectIdValue}/todos/${this.todoIdValue}/tasks/${this.taskIdValue}/search_members?q=${encodeURIComponent(query)}`;
    console.log("Fetching from URL:", url);

    try {
      const response = await fetch(url);
      console.log("Response status:", response.status);

      if (response.ok) {
        const data = await response.json();
        console.log("Users found:", data.users);
        callback(data.users);
      } else {
        console.error("Response not OK:", response.status);
        callback([]);
      }
    } catch (error) {
      console.error("Error searching users:", error);
      callback([]);
    }
  }
}
