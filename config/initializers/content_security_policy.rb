# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src     :self
    policy.base_uri        :self
    policy.form_action     :self
    policy.frame_ancestors :none
    policy.object_src      :none
    policy.font_src        :self, :data
    policy.img_src         :self, :data, :blob
    policy.script_src      :self, "https://challenges.cloudflare.com"
    policy.frame_src       "https://challenges.cloudflare.com"
    policy.connect_src     :self, "https://challenges.cloudflare.com"
    policy.style_src       :self, :unsafe_inline
  end

  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]

  # Primero en modo "solo reportar": el navegador avisa en la consola pero no bloquea.
  # Cuando confirmes que no hay errores, cambialo a false.
  config.content_security_policy_report_only = true
end
