class Form < ApplicationRecord
  include SpreadsheetConnectable

  belongs_to :area
  has_many :fields, -> { order(:position) }, class_name: "FormField",
           dependent: :destroy, inverse_of: :form
  has_many :submissions, dependent: :destroy

  enum :status, { draft: 0, published: 1, closed: 2 }

  delegate :organization, to: :area

  before_validation :generate_public_id, on: :create

  validates :title, presence: true, length: { maximum: 150 }
  validates :public_id, presence: true, uniqueness: true

  def to_param
    public_id
  end

  def effective_spreadsheet_id
    spreadsheet_id.presence || area.effective_spreadsheet_id
  end

  def spreadsheet_source
    return self if spreadsheet_connected?
    return area if area.spreadsheet_connected?
    organization if organization.spreadsheet_connected?
  end

  private

  def generate_public_id
    self.public_id ||= loop do
      token = SecureRandom.alphanumeric(10).downcase
      break token unless Form.exists?(public_id: token)
    end
  end
end