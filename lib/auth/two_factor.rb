# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Auth::TwoFactor

  attr_reader :user, :all_authentication_methods

  def self.authentication_method_classes
    @authentication_method_classes ||= Auth::TwoFactor::AuthenticationMethod.descendants.sort_by(&:name)
  end

  def initialize(user)
    @user = user

    @all_authentication_methods = self.class.authentication_method_classes.map { |authentication_method| authentication_method.new(user) }
  end

  def enabled?
    enabled_authentication_methods.present?
  end

  def available_authentication_methods
    enabled_authentication_methods.select(&:available?)
  end

  def enabled_authentication_methods
    all_authentication_methods.select(&:enabled?)
  end

  def verify?(method, payload)
    return false if method.nil?

    method_object = begin
      if method.eql?('recovery_codes')
        recovery_codes_object
      else
        authentication_method_object(method)
      end
    end

    return false if method_object.nil?

    result = method_object.verify(payload)

    return false if !result[:verified]

    method_object.update_user_config(result.except(:verified))

    true
  end

  def initiate_authentication(method)
    return {} if method.nil?

    method_object = method_object(method)
    return {} if method_object.nil?

    result = method_object.initiate_authentication
    return {} if result.nil?

    result
  end

  def verify_configuration?(method, payload, configuration)
    return false if method.nil?

    authentication_method_object = authentication_method_object(method)
    return false if authentication_method_object.nil?

    result = authentication_method_object.verify(payload, configuration)

    return false if !result[:verified]

    authentication_method_object.create_user_config(result.except(:verified))

    true
  end

  def authentication_method_object(method)
    all_authentication_methods.find { |all_authentication_method| all_authentication_method.method_name.eql?(method) }
  end

  def user_authentication_methods
    enabled_authentication_methods.select { |method| user_two_factor_configuration.key?(method.method_name.to_sym) }
  end

  def user_default_authentication_method
    default_method = user.preferences.dig(:two_factor_authentication, :default)
    return if default_method.nil?

    user_authentication_methods.find { |method| method.method_name.eql?(default_method) }
  end

  def user_setup_required?
    enabled? && !user_configured? && Setting.get('two_factor_authentication_enforce_role_ids').any? { |role_id| user.role_ids.include? role_id.to_i }
  end

  def user_configured?
    !user_default_authentication_method.nil?
  end

  def user_recovery_codes_exists?
    return false if !recovery_codes_enabled?

    recovery_codes_object.exists?
  end

  def recovery_codes_enabled?
    recovery_codes_object.enabled?
  end

  private

  def recovery_codes_object
    @recovery_codes_object ||= Auth::TwoFactor::RecoveryCodes.new(user)
  end

  def user_two_factor_configuration
    return if user.two_factor_preferences.authentication_methods.nil?

    user.two_factor_preferences.authentication_methods.to_h do |two_factor_pref|
      [
        two_factor_pref.method.to_sym,
        two_factor_pref.configuration,
      ]
    end
  end
end
