# frozen_string_literal: true

# Provides full-text search functionality using pg_search gem.
#
# ApplicationRecord extends this module, so every model gets `searchable_by`
# as a class method without any extra mixin overhead. PgSearch::Model is only
# mixed into a model the first time it calls `searchable_by`.
#
# Example:
#   class Entry < ApplicationRecord
#     searchable_by %i[first_name last_name email], using: {
#       trigram: { word_similarity: true }
#     }
#   end
#
#   Entry.search('john')

module SearchableConcern
  def searchable_by(*columns, **options)
    include PgSearch::Model unless include?(PgSearch::Model)

    default_options = {
      against: columns,
      using: { tsearch: { prefix: true } }
    }

    pg_search_scope :search_by_text, default_options.deep_merge(options)

    scope :search, ->(query) { query.present? ? search_by_text(query).reorder(nil) : self }
  end
end
