import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "optionsField", "optionsInput"]

  connect() {
    this.toggleOptions()
  }

  toggleOptions() {
    const type = this.typeSelectTarget.value
    if (type === "select") {
      this.optionsFieldTarget.classList.remove("hidden")
      this.optionsInputTarget.required = true
    } else {
      this.optionsFieldTarget.classList.add("hidden")
      this.optionsInputTarget.required = false
    }
  }
}
