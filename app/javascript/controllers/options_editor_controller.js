import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Editor de opciones: agregar, borrar, reordenar, pegar listas e imágenes
export default class extends Controller {
  static targets = ["list", "template"]

  connect() {
    this.sortable = Sortable.create(this.listTarget, {
      handle: ".drag-handle",
      animation: 150,
      onEnd: () => this.renumber()
    })
    this.form = this.element.closest("form")
    this.form?.addEventListener("submit", this.renumber)
    this.renumber()
  }

  disconnect() {
    this.sortable?.destroy()
    this.form?.removeEventListener("submit", this.renumber)
  }

  add(event) {
    const row = this.buildRow("")
    this.listTarget.append(row)
    this.renumber()
    if (event) row.querySelector("[data-role=label]").focus()
  }

  remove(event) {
    const row = event.target.closest(".option-row")
    if (row.querySelector("[data-role=id]")) {
      row.querySelector("[data-role=destroy]").value = "1"
      row.classList.add("d-none")
    } else {
      row.remove()
    }
    this.renumber()
  }

  // Enter crea una opción nueva debajo, en lugar de enviar el formulario
  keydown(event) {
    if (event.key !== "Enter") return
    event.preventDefault()
    const row = this.buildRow("")
    event.target.closest(".option-row").after(row)
    this.renumber()
    row.querySelector("[data-role=label]").focus()
  }

  // Pegar varias líneas crea una opción por renglón
  paste(event) {
    const text = (event.clipboardData || window.clipboardData).getData("text")
    const lines = text.split(/\r?\n/).map((line) => line.trim()).filter(Boolean)
    if (lines.length < 2) return

    event.preventDefault()
    const input = event.target
    let current = input.closest(".option-row")
    if (input.value.trim() === "") input.value = lines.shift()

    lines.forEach((line) => {
      const row = this.buildRow(line)
      current.after(row)
      current = row
    })
    this.renumber()
  }

  preview(event) {
    const file = event.target.files[0]
    if (!file) return
    const row = event.target.closest(".option-row")
    const img = document.createElement("img")
    img.src = URL.createObjectURL(file)
    row.querySelector("[data-role=preview]").replaceChildren(img)
    row.querySelector("[data-role=remove-image]").value = "0"
  }

  removeImage(event) {
    const row = event.target.closest(".option-row")
    row.querySelector("[data-role=remove-image]").value = "1"
    row.querySelector("input[type=file]").value = ""
    row.querySelector("[data-role=preview]").textContent = "+ Imagen"
  }

  buildRow(value) {
    const uid = `${Date.now()}${Math.floor(Math.random() * 1000)}`
    const wrapper = document.createElement("div")
    wrapper.innerHTML = this.templateTarget.innerHTML.replaceAll("NEW_OPTION", uid).trim()
    const row = wrapper.firstElementChild
    row.querySelector("[data-role=label]").value = value
    return row
  }

  renumber = () => {
    this.listTarget.querySelectorAll(":scope > .option-row").forEach((row, i) => {
      row.querySelector("[data-role=position]").value = i + 1
    })
  }
}