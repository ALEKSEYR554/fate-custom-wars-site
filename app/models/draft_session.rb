class DraftSession < ApplicationRecord
  before_create :generate_slug
  before_create :set_expiration

  private

  def generate_slug
    loop do
      self.slug = SecureRandom.hex(4)
      break unless DraftSession.exists?(slug: self.slug)
    end
  end

  def set_expiration
    self.expires_at = 1.hour.from_now
  end
end
