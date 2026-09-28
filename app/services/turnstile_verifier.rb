class TurnstileVerifier
  URL = URI("https://challenges.cloudflare.com/turnstile/v0/siteverify")

  # Claves públicas de prueba de Cloudflare: siempre aprueban
  TEST_SITE_KEY   = "1x00000000000000000000AA".freeze
  TEST_SECRET_KEY = "1x0000000000000000000000000000000AA".freeze

  class << self
    def site_key
      ENV["TURNSTILE_SITE_KEY"].presence ||
        Rails.application.credentials.dig(:turnstile, :site_key).presence ||
        (TEST_SITE_KEY unless Rails.env.production?)
    end

    def configured?
      site_key.present? && secret_key.present?
    end

    def verify(token, remote_ip)
      if token.blank?
        Rails.logger.warn("Turnstile: no llegó el token (el widget no se cargó o está fuera del formulario)")
        return false
      end

      payload = { secret: secret_key, response: token }
      payload[:remoteip] = remote_ip if public_ip?(remote_ip)

      request = Net::HTTP::Post.new(URL, "Content-Type" => "application/json")
      request.body = payload.to_json

      response = Net::HTTP.start(URL.host, URL.port, use_ssl: true, open_timeout: 3, read_timeout: 5) do |http|
        http.request(request)
      end
      body = JSON.parse(response.body)
      Rails.logger.warn("Turnstile rechazó el token: #{body['error-codes'].inspect} (HTTP #{response.code})") unless body["success"]
      body["success"] == true
    rescue StandardError => e
      Rails.logger.warn("Turnstile no respondió: #{e.class}: #{e.message}")
      false
    end

    private

    def public_ip?(ip)
      address = IPAddr.new(ip.to_s)
      !(address.loopback? || address.private? || address.link_local?)
    rescue IPAddr::InvalidAddressError
      false
    end

    def secret_key
      ENV["TURNSTILE_SECRET_KEY"].presence ||
        Rails.application.credentials.dig(:turnstile, :secret_key).presence ||
        (TEST_SECRET_KEY unless Rails.env.production?)
    end
  end
end