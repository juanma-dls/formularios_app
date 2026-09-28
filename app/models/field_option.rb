class FieldOption < ApplicationRecord
  belongs_to :form_field
  validates :label, presence: true
end