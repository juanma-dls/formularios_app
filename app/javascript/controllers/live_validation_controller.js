import { Controller } from "@hotwired/stimulus"

// Mismos mensajes que valida el servidor
const MESSAGES = {
  required: "Esta pregunta es obligatoria.",
  terms: "Para enviar tenés que aceptar las bases y condiciones.",
  dni: "El DNI debe tener 7 u 8 números.",
  phone: "Ingresá un teléfono con código de área.",
  phoneParts: "Completá el código de área y el número.",
  phoneSplit: "Revisá el código de área y el número: entre los dos tienen que sumar 10 dígitos.",
  email: "Ingresá un email válido.",
  number: "Ingresá un número válido."
}
const GROUP_TYPES = ["single_choice", "image_choice", "multiple_choice", "terms"]

// Valida al salir de cada campo y, si el servidor devolvió errores, lleva al primero
export default class extends Controller {
  static targets = ["field"]

  connect() {
    requestAnimationFrame(() => {
      const first = this.fieldTargets.find((field) => field.hasAttribute("data-has-error"))
      if (first) this.focusField(first)
    })
  }

  check(event) {
    const field = event.target.closest("[data-type]")
    if (!field || !this.fieldTargets.includes(field)) return

    if (event.type === "focusout" && field.contains(event.relatedTarget)) return

    const message = this.errorFor(field)
    const shown = !field.querySelector("[data-role=error]").hidden
    // Al salir de un campo vacío no se reta; se avisa recién si intenta enviar
    const emptyError = message === MESSAGES.required || message === MESSAGES.terms
    if (event.type === "focusout" && emptyError && !shown) return

    this.show(field, message)
  }

  submit(event) {
    if (event.defaultPrevented) return

    const invalid = this.fieldTargets.filter((field) => {
      const message = this.errorFor(field)
      this.show(field, message)
      return message
    })
    if (invalid.length) {
      event.preventDefault()
      this.focusField(invalid[0])
    }
  }

  errorFor(field) {
    const type = field.dataset.type
    const required = field.dataset.required === "true"

    if (type === "phone" && field.dataset.split === "true") return this.splitPhoneError(field, required)

    const inputs = [...field.querySelectorAll("input:not([type=hidden]), select, textarea")]
    const value = GROUP_TYPES.includes(type)
      ? (inputs.some((input) => input.checked) ? "ok" : "")
      : (inputs[0]?.value || "").trim()

    if (!value) return required ? (type === "terms" ? MESSAGES.terms : MESSAGES.required) : null

    switch (type) {
      case "dni":    return /^\d{7,8}$/.test(value.replace(/\D/g, "")) ? null : MESSAGES.dni
      case "phone":  return /^\+?\d{8,15}$/.test(value.replace(/[^\d+]/g, "")) ? null : MESSAGES.phone
      case "email":  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value) ? null : MESSAGES.email
      case "number": return /^-?\d+([.,]\d+)?$/.test(value) ? null : MESSAGES.number
      default:       return null
    }
  }

  show(field, message) {
    const box = field.querySelector("[data-role=error]")
    box.textContent = message || ""
    box.hidden = !message
    field.classList.toggle("border-danger", Boolean(message))
  }

  focusField(field) {
    this.dispatch("reveal", { detail: { field } })
    requestAnimationFrame(() => {
      field.scrollIntoView({ behavior: "smooth", block: "center" })
      field.querySelector("input:not([type=hidden]), select, textarea")?.focus({ preventScroll: true })
    })
  }

  validateWithin(container) {
    const invalid = this.fieldTargets
      .filter((field) => container.contains(field))
      .filter((field) => {
        const message = this.errorFor(field)
        this.show(field, message)
        return message
      })
    if (invalid.length) this.focusField(invalid[0])
    return invalid.length === 0
  }

  splitPhoneError(field, required) {
    const [areaInput, numberInput] = field.querySelectorAll("input")
    const area = areaInput.value.replace(/\D/g, "").replace(/^0+/, "")
    let number = numberInput.value.replace(/\D/g, "")

    if (!area && !number) return required ? MESSAGES.required : null
    if (!area || !number) return MESSAGES.phoneParts
    if ((area + number).length === 12 && number.startsWith("15")) number = number.slice(2)
    if (area.length < 2 || area.length > 4 || (area + number).length !== 10) return MESSAGES.phoneSplit
    return null
  }
}