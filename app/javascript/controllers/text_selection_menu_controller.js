import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "modal", "taskTitle", "todoSelect"]
  static values = {
    projectId: String,
    todos: Array
  }

  connect() {
    this.selectedText = ""
    this._handleMouseup = this.handleMouseup.bind(this)
    document.addEventListener("mouseup", this._handleMouseup)
  }

  disconnect() {
    document.removeEventListener("mouseup", this._handleMouseup)
  }

  handleMouseup(event) {
    if (this.menuTarget.contains(event.target)) return
    if (this.modalTarget.contains(event.target)) return

    setTimeout(() => {
      const selection = window.getSelection()
      const text = selection.toString().trim()

      if (text.length > 0 && this.selectionInComments(selection)) {
        this.selectedText = text
        this.showMenu(selection)
      } else {
        this.hideMenu()
      }
    }, 10)
  }

  selectionInComments(selection) {
    try {
      return this.element.contains(selection.anchorNode) || this.element.contains(selection.focusNode)
    } catch {
      return false
    }
  }

  showMenu(selection) {
    const range = selection.getRangeAt(0)
    const rect = range.getBoundingClientRect()
    const menu = this.menuTarget

    menu.classList.remove("hidden")

    requestAnimationFrame(() => {
      const menuHeight = menu.offsetHeight
      const menuWidth = menu.offsetWidth

      let top = rect.top - menuHeight - 8
      if (top < 8) top = rect.bottom + 8

      let left = rect.left + (rect.width / 2) - (menuWidth / 2)
      left = Math.max(8, Math.min(left, window.innerWidth - menuWidth - 8))

      menu.style.top = `${top}px`
      menu.style.left = `${left}px`
    })
  }

  hideMenu() {
    this.menuTarget.classList.add("hidden")
  }

  openCreateTaskModal() {
    this.hideMenu()

    const select = this.todoSelectTarget
    select.innerHTML = '<option value="">— Selecciona una lista —</option>'
    this.todosValue.forEach(todo => {
      const option = document.createElement("option")
      option.value = todo.id
      option.textContent = todo.name
      select.appendChild(option)
    })

    this.taskTitleTarget.value = this.selectedText
    this.modalTarget.classList.remove("hidden")
    this.taskTitleTarget.focus()
    this.taskTitleTarget.select()
  }

  closeModal() {
    this.modalTarget.classList.add("hidden")
    this.selectedText = ""
  }

  backdropClick(event) {
    if (event.target === event.currentTarget) {
      this.closeModal()
    }
  }

  async createTask(event) {
    event.preventDefault()

    const todoId = this.todoSelectTarget.value
    const title = this.taskTitleTarget.value.trim()

    if (!todoId) {
      this.todoSelectTarget.focus()
      return
    }
    if (!title) {
      this.taskTitleTarget.focus()
      return
    }

    const url = `/projects/${this.projectIdValue}/todos/${todoId}/tasks`
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    const formData = new FormData()
    formData.append("task[title]", title)
    formData.append("task[done]", "false")

    const submitBtn = event.submitter || event.target.querySelector('[type="submit"]')
    if (submitBtn) submitBtn.disabled = true

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: { "X-CSRF-Token": csrfToken },
        body: formData,
        redirect: "follow"
      })

      if (response.ok) {
        const todoName = this.todoSelectTarget.options[this.todoSelectTarget.selectedIndex].text
        this.closeModal()
        this.showFlash(`Tarea creada en "${todoName}"`)
      } else {
        this.showFlash("Error al crear la tarea", "error")
      }
    } catch {
      this.showFlash("Error al crear la tarea", "error")
    } finally {
      if (submitBtn) submitBtn.disabled = false
    }
  }

  showFlash(message, type = "success") {
    const flash = document.getElementById("flash-messages")
    if (!flash) return

    const color = type === "success"
      ? "bg-green-100 text-green-800 border-green-200"
      : "bg-red-100 text-red-800 border-red-200"
    flash.innerHTML = `<div class="border ${color} px-4 py-2 rounded-lg mb-2 text-sm">${message}</div>`
    setTimeout(() => { flash.innerHTML = "" }, 4000)
  }
}
