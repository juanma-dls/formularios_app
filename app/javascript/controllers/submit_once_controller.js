import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="submit-once"
export default class extends Controller {
  disable(event) {
    if (event.defaultPrevented) return

    this.element.querySelectorAll("[type=submit]").forEach((button) => {
      button.disabled = true
      button.textContent = "Enviando…"
    })
  }
}
