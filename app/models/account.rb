class Account < ActiveRecord::Base
  validates :supplier, presence: true, uniqueness: true
  validates :identifier, :password, presence: true

  before_save :encrypt_password

  def encrypt_password
    self.password = encrypt(self.password)
  end

  def self.decrypt_password(password)
    decrypt(password)
  end

  SECURE = "jaR0VjObhSk9kd4Mr4msLTJLH1JFYsxMkp6WurYjBQEu2oeZzO"
  CIPHER = "aes-256-cbc"

  def encrypt(password)
    crypt = ActiveSupport::MessageEncryptor.new(SECURE, CIPHER)
    crypt.encrypt_and_sign(password)
  end

  def self.decrypt(password)
    crypt = ActiveSupport::MessageEncryptor.new(SECURE, CIPHER)
    crypt.decrypt_and_verify(password)
  end
end
