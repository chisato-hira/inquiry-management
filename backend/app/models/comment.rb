class Comment < ApplicationRecord
  COMMENT_TYPES = %w[manual system].freeze

  belongs_to :inquiry
  belongs_to :staff, optional: true

  validates :comment_type, presence: true, inclusion: { in: COMMENT_TYPES }
  validates :content, presence: true
end
