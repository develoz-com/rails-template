# frozen_string_literal: true

# State transition tracking on top of a Rails enum + jsonb log. Replaces
# statesman for models that have:
#
#   - a `status` enum column (string)
#   - a `status_transitions` jsonb column (default: `[]`)
#
# Each entry in `status_transitions` is `{ "to_state" => "...", "created_at" => "<ISO8601>" }`
# (chronological, append-only). When `transition_metadata` is set before save,
# it's stored on the new entry under `metadata`.
#
# Strict mode (state machine — only declared transitions allowed):
#
#   class Order < ApplicationRecord
#     states pending: %i[paid cancelled],
#            paid:    %i[shipped refunded],
#            shipped: [],
#            cancelled: [],
#            refunded: []
#   end
#
# Free mode (any-to-any):
#
#   class Article < ApplicationRecord
#     states %i[draft review published archived]
#   end
#
# `states(...)` declares:
#
#   - `enum :status, { ... }, default: <first>, suffix: <true|false>` — drive
#     transitions via the standard Rails enum bang setters (`<state>!` /
#     `<state>_status!`); the concern hooks status changes via validation
#     and a before_save callback so `update`/`save`/manual `status =` all work
#   - a `Klass.transitions` class method returning the transition map
#     (or `nil` in free mode)
#   - dynamic `can_be_<state>?` predicates (one per declared state)
#   - an `in_state(*states)` scope
#
# Transition history is recorded automatically on save when `status` changed.
# To attach metadata to a transition, set `transition_metadata` (an
# attr_accessor cleared after each save):
#
#   page.update!(status: 'analysing_error', transition_metadata: { error: msg })
#
# Disallowed transitions surface as a regular validation error on `:status`,
# so `update!` / `<state>!` raise `ActiveRecord::RecordInvalid`.
module Transitionable
  StateTransition = Struct.new(:to_state, :metadata, :created_at, keyword_init: true)

  def states(*positional, suffix: true, **kwargs)
    states_list, transitions_map = parse_states(positional, kwargs)

    enum(:status, states_list.index_with(&:to_s), default: states_list.first, suffix:)
    define_singleton_method(:transitions) { transitions_map }

    scope :in_state, ->(*values) { where(status: values.flatten.map(&:to_s)) }

    include Transitionable::Methods

    states_list.each do |state|
      define_method("can_be_#{state}?") { transition_allowed?(state) }
    end
  end

  private

  def parse_states(positional, kwargs)
    if kwargs.any?
      raise ArgumentError, "states accepts either a transitions hash or a list of states, not both" if positional.any?

      transitions_map = freeze_transitions(kwargs)
      [ transitions_map.keys.map(&:to_s), transitions_map ]
    elsif positional.length == 1 && positional.first.is_a?(Hash)
      transitions_map = freeze_transitions(positional.first)
      [ transitions_map.keys.map(&:to_s), transitions_map ]
    else
      list = positional.flatten.map(&:to_s).freeze
      raise ArgumentError, "states requires at least one state" if list.empty?

      [ list, nil ]
    end
  end

  def freeze_transitions(hash)
    hash.transform_keys(&:to_sym)
        .transform_values { |targets| Array(targets).map(&:to_sym).freeze }
        .freeze
  end

  module Methods
    extend ActiveSupport::Concern

    included do
      attr_accessor :transition_metadata

      validate :validate_status_transition, if: :status_changed?, on: :update
      before_update :record_status_transition, if: :status_changed?
      before_create :record_status_transition, unless: -> { status.blank? || status_transitions.present? }
    end

    def last_transition
      return if status_transitions.blank?

      record = status_transitions.last
      Transitionable::StateTransition.new(
        to_state: record["to_state"],
        metadata: record["metadata"] || {},
        created_at: record["created_at"]
      )
    end

    def status_times
      status_transitions.each_with_object([]) do |entry, acc|
        time = Time.zone.parse(entry["created_at"].to_s)
        previous_time = acc.last&.[](:time) || created_at
        acc << { status: entry["to_state"], previous_time:, time:, duration: time - previous_time }
      end
    end

    private

    def transition_allowed?(target)
      transitions = self.class.transitions
      return true if transitions.nil?

      from = (status_changed? ? status_was : status)&.to_sym
      transitions[from]&.include?(target.to_sym) || false
    end

    def validate_status_transition
      return if transition_allowed?(status)

      errors.add(:status, "cannot transition from #{status_was.inspect} to #{status.inspect}")
    end

    def record_status_transition
      record = { "to_state" => status.to_s, "created_at" => Time.current.iso8601(6) }
      record["metadata"] = transition_metadata.to_h.deep_stringify_keys if transition_metadata.present?
      self.status_transitions = Array(status_transitions) + [ record ]
      self.transition_metadata = nil
    end
  end
end
