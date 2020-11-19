# frozen_string_literal: true

class EncryptionService
  # encryption_salt = Base64.encode64(
  #   SecureRandom.random_bytes(
  #     ActiveSupport::MessageEncryptor.key_len
  #   )
  # )
  KEY = ActiveSupport::KeyGenerator.new(
    Rails.application.secret_key_base
  ).generate_key(
    Base64.decode64(Rails.application.credentials[:encryption_salt]),
    ActiveSupport::MessageEncryptor.key_len
  ).freeze

  private_constant :KEY

  delegate :encrypt_and_sign, :decrypt_and_verify, to: :encryptor

  def self.encrypt(value)
    new.encrypt_and_sign(value)
  end

  def self.decrypt(value)
    new.decrypt_and_verify(value)
  end

  private

  def encryptor
    ActiveSupport::MessageEncryptor.new(KEY)
  end
end
