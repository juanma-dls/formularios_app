import { Controller } from "@hotwired/stimulus"

// Copia el texto al portapapeles y confirma en el botón
export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    try {
      await navigator.clipboard.writeText(this.sourceTarget.value)
    } catch {
      this.sourceTarget.select()
      document.execCommand("copy")
    }
    const original = this.buttonTarget.innerHTML
    this.buttonTarget.innerHTML = '<i class="bi bi-check2 me-1"></i>¡Copiado!'
    setTimeout(() => { this.buttonTarget.innerHTML = original }, 2000)
  }
}