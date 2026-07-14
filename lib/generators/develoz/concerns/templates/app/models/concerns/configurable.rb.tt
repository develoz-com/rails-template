# frozen_string_literal: true

# Convenience helpers for models that own polymorphic [[Configuration]] records.
#
# ApplicationRecord includes this module, so every model can read and write its
# scoped configuration without repeating the for_configurable/find_by dance.
#
#   client.configuration_value(:features) # => { 'automation' => true }
#
# == The `configurable` DSL
#
# `configurable` is the single entrypoint for a configuration-backed attribute.
# Each declaration maps a virtual attribute to its own dedicated Configuration key
# (named after the attribute); the stored value IS the attribute value.
#
# The generated attribute is writable: assignments are buffered and persisted to
# the key on save, so controllers just mass-assign and never touch Configuration
# directly. Reads are lazy (the key is only queried when the reader is called).
#
#   class ClientPlatform < ApplicationRecord
#     configurable :highest_format_only, :boolean
#   end
#
#   client_platform.update!(highest_format_only: true)
#   client_platform.highest_format_only?  # => true
#
# The `type` drives the absent-value default (`:hash` => {}, `:array` => []),
# kept consistent with `:boolean`; pass `default:` only to override it. Use
# `global_fallback: true` to merge the global Configuration value under the
# record-scoped one (scoped wins):
#
#   configurable :features, :hash, global_fallback: true
#
# Assigning `nil` deletes the scoped record. Override `name=` in the model for any
# casting/normalisation, calling `write_configuration(name, value)` with the result.

module Configurable
  extend ActiveSupport::Concern

  class_methods do
    def configurable(name, type = nil, default: nil, global_fallback: false)
      name = name.to_sym
      install_configurable_persistence

      define_method(name) { read_configuration(name, type, default, global_fallback) }
      define_method("#{name}=") { |value| write_configuration(name, cast_configuration(value, type)) }
      define_method("#{name}?") { ActiveModel::Type::Boolean.new.cast(public_send(name)) == true } if type == :boolean
    end

    private

    def install_configurable_persistence
      return if singleton_class.method_defined?(:configurable?)

      define_singleton_method(:configurable?) { true }
      after_save :persist_configurations
    end
  end

  def configuration_for(key)
    Configuration.for_configurable(self).active.find_by(key:)
  end

  def configuration_value(key, default: nil)
    key = key.to_sym
    if configurations.key?(key)
      pending = configurations[key]
      return pending.nil? ? default : pending
    end

    configuration = configuration_for(key)
    configuration ? configuration.value : default
  end

  def update_configuration(key, value)
    configuration = Configuration.for_configurable(self).find_or_initialize_by(key:)
    configuration.update!(value:, active: true)
    configuration
  end

  def delete_configuration(key)
    Configuration.for_configurable(self).where(key:).destroy_all
  end

  def write_configuration(key, value)
    configurations[key.to_sym] = value
  end

  private

  def configurations
    @configurations ||= {}
  end

  def cast_configuration(value, type)
    type == :boolean ? ActiveModel::Type::Boolean.new.cast(value) : value
  end

  def configurable_default_for(type)
    case type
    when :hash then {}
    when :array then []
    end
  end

  def read_configuration(key, type, default, global_fallback)
    default = configurable_default_for(type) if default.nil?
    scoped = configuration_value(key, default:)
    return scoped unless global_fallback

    (Configuration.global_value(key) || {}).merge(scoped || {})
  end

  def persist_configurations
    configurations.each do |key, value|
      value.nil? ? delete_configuration(key) : update_configuration(key, value)
    end
    configurations.clear
  end
end
