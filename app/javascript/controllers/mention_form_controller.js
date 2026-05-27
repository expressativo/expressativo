import { Controller } from "@hotwired/stimulus"

// Lexxy registers a one-shot "trigger listener" that unregisters itself when @
// is detected, opens the popup, and is re-added when the popup closes.
// If that cycle breaks (e.g. after inserting a mention, deleting it, and typing
// @ again) the trigger listener may not be active. Fix: on every @ keydown,
// force-reconnect the <lexxy-prompt> element by removing it from the DOM and
// re-inserting it synchronously. This fires connectedCallback → fresh trigger
// listener → the @ insertion in the next tick is caught correctly.
export default class extends Controller {
  connect() {
    this.lexxyEditor = this.element.querySelector("lexxy-editor")
    if (!this.lexxyEditor) return

    this.onKeydown = this.onKeydown.bind(this)
    this.lexxyEditor.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    if (this.lexxyEditor) {
      this.lexxyEditor.removeEventListener("keydown", this.onKeydown)
    }
  }

  onKeydown(event) {
    if (event.key !== "@") return

    const prompt = this.lexxyEditor.querySelector("lexxy-prompt")
    if (!prompt) return
    if (prompt.open) return  // popup already open, don't interfere

    // Synchronously remove + re-insert to trigger disconnectedCallback →
    // connectedCallback which re-registers the trigger listener. This happens
    // before the browser inserts the @ character, so the new listener will
    // catch the resulting editor update.
    const parent = prompt.parentNode
    const anchor = prompt.nextSibling
    parent.removeChild(prompt)
    parent.insertBefore(prompt, anchor)
  }
}
