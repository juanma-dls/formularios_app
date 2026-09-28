import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="submit-once"
export default class extends Controller {
  disable() {
    this.element.querySelectorAll("[type=submit]").forEach((button) => {
      button.disabled = true
      button.textContent = "Enviando…"
    })
  }
}
