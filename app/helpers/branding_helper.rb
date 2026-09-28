module BrandingHelper
  def brand_css(organization)
    color = organization&.brand_color
    return "" unless color&.match?(Organization::BRAND_COLOR)

    hover = shade(color, 0.85)
    text = readable_text_on(color)

    <<~CSS
      :root { --brand: #{color}; }
      .btn-primary {
        --bs-btn-bg: #{color}; --bs-btn-border-color: #{color}; --bs-btn-color: #{text};
        --bs-btn-hover-bg: #{hover}; --bs-btn-hover-border-color: #{hover}; --bs-btn-hover-color: #{text};
        --bs-btn-active-bg: #{hover}; --bs-btn-active-border-color: #{hover}; --bs-btn-active-color: #{text};
      }
      .btn-outline-primary {
        --bs-btn-color: #{color}; --bs-btn-border-color: #{color};
        --bs-btn-hover-bg: #{color}; --bs-btn-hover-border-color: #{color}; --bs-btn-hover-color: #{text};
        --bs-btn-active-bg: #{color}; --bs-btn-active-border-color: #{color}; --bs-btn-active-color: #{text};
      }
      .form-check-input:checked { background-color: #{color}; border-color: #{color}; }
    CSS
  end

  private

  def shade(hex, factor)
    channels = hex.delete("#").scan(/../).map { |c| (c.hex * factor).round.clamp(0, 255) }
    format("#%02x%02x%02x", *channels)
  end

  # Texto blanco si alcanza un contraste de 4.5:1; si no, texto oscuro
  def readable_text_on(hex)
    r, g, b = hex.delete("#").scan(/../).map do |c|
      v = c.hex / 255.0
      v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055)**2.4
    end
    luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
    luminance <= 0.18 ? "#ffffff" : "#111a2b"
  end
end