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
      return false if token.blank?

      response = Net::HTTP.start(URL.host, URL.port, use_ssl: true, open_timeout: 3, read_timeout: 5) do |http|
        http.post(URL.path, URI.encode_www_form(secret: secret_key, response: token, remoteip: remote_ip))
      end
      JSON.parse(response.body)["success"] == true
    rescue StandardError => e
      Rails.logger.warn("Turnstile no respondió: #{e.class}: #{e.message}")
      false
    end

    private

    def secret_key
      ENV["TURNSTILE_SECRET_KEY"].presence ||
        Rails.application.credentials.dig(:turnstile, :secret_key).presence ||
        (TEST_SECRET_KEY unless Rails.env.production?)
    end
  end
end