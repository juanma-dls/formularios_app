module FieldPresets
  PRESETS = {
    "datos_personales" => {
      name: "Datos personales",
      description: "Nombre, apellido, DNI, sexo, fecha de nacimiento, teléfono y email",
      fields: [
        { field_type: "short_text",    label: "Nombre", required: true },
        { field_type: "short_text",    label: "Apellido", required: true },
        { field_type: "dni",           label: "DNI", required: true },
        { field_type: "single_choice", label: "Sexo", required: true,
          help_text: "Como figura en tu DNI", options: %w[Femenino Masculino X] },
        { field_type: "date",          label: "Fecha de nacimiento", required: true },
        { field_type: "phone",         label: "Teléfono", required: true,
          help_text: "Con código de área, sin el 0 ni el 15" },
        { field_type: "email",         label: "Email" }
      ]
    },
  }.freeze
end