# frozen_string_literal: true

# OptimizedFinders provides generic find_for and for methods that optimize queries
# when associations are already loaded or when searching by non-database fields.
#
# Usage:
#   # Find a single record
#   audit.prices.find_for(variant: 'hd', license: 'buy')
#
#   # Find multiple records
#   audit.prices.for(variant: 'hd', license: 'buy')
#
# Optimization logic:
#   - If called on a loaded association, uses Ruby enumerable methods (no SQL)
#   - If any search field is not a database column, uses Ruby enumerable methods
#   - Otherwise, uses database queries (find_by/where)
module OptimizedFinders
  extend ActiveSupport::Concern

  # Class methods for finding records
  module ClassMethods
    # Find a single record matching the given attributes
    # Optimized to use in-memory search when associations are loaded
    def find_for(**attributes)
      find_by(attributes)
    end

    # Find multiple records matching the given attributes
    # Optimized to use in-memory search when associations are loaded
    def for(**attributes)
      where(attributes)
    end

    def not_for(**attributes)
      where.not(attributes)
    end

    def gather(*attributes)
      pluck(*attributes)
    end
  end

  # Module to prepend to ActiveRecord::Associations::CollectionProxy
  # This provides optimized implementations for loaded associations
  module CollectionProxyOptimizations
    # Find a single record matching the given attributes
    # Uses in-memory search if association is loaded or if any attribute is not a database column
    def find_for(**attributes)
      return super unless should_use_memory_search?(attributes)

      to_a.find { |record| match_attributes?(record, attributes) }
    end

    # Find multiple records matching the given attributes
    # Uses in-memory search if association is loaded or if any attribute is not a database column
    def for(**attributes)
      return super unless should_use_memory_search?(attributes)

      to_a.select { |record| match_attributes?(record, attributes) }
    end

    # Find multiple records NOT matching the given attributes
    # Uses in-memory search if association is loaded or if any attribute is not a database column
    def not_for(**attributes)
      return super unless should_use_memory_search?(attributes)

      to_a.reject { |record| match_attributes?(record, attributes) }
    end

    # Extract column values from records, like pluck
    # Uses in-memory search if association is loaded or if any attribute is not a database column
    def gather(*attributes)
      return pluck(*attributes) unless should_use_memory_search?(attributes)
      return to_a.map(&attributes.first) if attributes.size == 1

      to_a.map { |record| read_attributes(record, attributes) }
    end

    private

    def match_attributes?(record, attributes)
      attributes.all? do |key, value|
        record_value = record.public_send(key)
        value.is_a?(Array) ? value.include?(record_value) : record_value == value
      end
    end

    def read_attributes(record, attributes)
      attributes.map { |attribute| record.public_send(attribute) }
    end

    # Determines if we should search in memory vs database
    # Returns true if:
    #   - Association is already loaded, OR
    #   - Any search attribute is not a database column (computed/virtual attribute)
    def should_use_memory_search?(attributes)
      return true if loaded?

      keys = attributes.is_a?(Hash) ? attributes.keys : attributes
      keys.any? { |key| klass.column_names.exclude?(key.to_s) }
    end
  end
end

# Prepend optimizations to CollectionProxy so they take precedence
ActiveRecord::Associations::CollectionProxy.prepend(OptimizedFinders::CollectionProxyOptimizations)
