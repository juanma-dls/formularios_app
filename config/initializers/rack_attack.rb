class Rack::Attack
  PUBLIC_FORM_POST = %r{\A/f/[a-z0-9]+\z}

  # En desarrollo Rails no usa caché por defecto, así que le damos una en memoria.
  # En producción usa la de Rails (Solid Cache), compartida entre procesos.
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new if Rails.env.development?

  blocklist("public_forms/oversized") do |req|
    req.post? && req.path.match?(PUBLIC_FORM_POST) && req.content_length.to_i > 100_000
  end

  throttle("public_forms/ip/minute",
           limit: ENV.fetch("PUBLIC_FORM_LIMIT_PER_MINUTE", 20).to_i, period: 1.minute) do |req|
    req.ip if req.post? && req.path.match?(PUBLIC_FORM_POST)
  end

  throttle("public_forms/ip/hour",
           limit: ENV.fetch("PUBLIC_FORM_LIMIT_PER_HOUR", 300).to_i, period: 1.hour) do |req|
    req.ip if req.post? && req.path.match?(PUBLIC_FORM_POST)
  end

  self.throttled_responder = lambda do |_request|
    body = <<~HTML
      <!DOCTYPE html>
      <html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Demasiados envíos</title></head>
      <body style="font-family: system-ui, sans-serif; max-width: 36rem; margin: 4rem auto; padding: 0 1rem; text-align: center">
        <h1 style="font-size: 1.5rem">Demasiados envíos</h1>
        <p>Recibimos muchas respuestas desde tu conexión en poco tiempo. Esperá un minuto y volvé a intentar.</p>
      </body></html>
    HTML
    [429, { "content-type" => "text/html; charset=utf-8", "retry-after" => "60" }, [body]]
  end
end