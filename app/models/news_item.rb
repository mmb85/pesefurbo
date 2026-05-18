# ==============================================================================
# app/models/news_item.rb
# ==============================================================================
class NewsItem < ApplicationRecord
  belongs_to :club,   optional: true
  belongs_to :player, optional: true
  belongs_to :match,  optional: true

  scope :unread,     -> { where(read: false) }
  scope :important,  -> { where(important: true) }
  scope :recent,     -> { order(published_on: :desc) }
end
