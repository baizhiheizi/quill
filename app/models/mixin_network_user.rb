# frozen_string_literal: true

# == Schema Information
#
# Table name: mixin_network_users
#
#  id            :bigint           not null, primary key
#  encrypted_pin :string
#  name          :string
#  owner_type    :string
#  pin_token     :string
#  private_key   :string
#  raw           :json
#  uuid          :uuid
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  owner_id      :bigint
#  session_id    :uuid
#
# Indexes
#
#  index_mixin_network_users_on_owner_type_and_owner_id  (owner_type,owner_id)
#  index_mixin_network_users_on_uuid                     (uuid) UNIQUE
#
class MixinNetworkUser < ApplicationRecord
  DEFAULT_AVATAR_FILE = Rails.application.root.join("app/packs/images/#{Settings.logo_file || 'logo.png'}")

  include Encryptable

  belongs_to :owner, optional: true, inverse_of: false, polymorphic: true
  has_many :snapshots, class_name: 'MixinNetworkSnapshot', foreign_key: :user_id, primary_key: :uuid, dependent: :nullify, inverse_of: :wallet
  has_many :swap_orders, foreign_key: :user_id, primary_key: :uuid, dependent: :nullify, inverse_of: :wallet
  has_many :transfers, foreign_key: :wallet_id, primary_key: :uuid, dependent: :nullify, inverse_of: :wallet

  validates :name, presence: true
  validates :pin_token, presence: true
  validates :private_key, presence: true
  validates :uuid, presence: true
  validates :session_id, presence: true

  before_validation :setup_attributes, on: :create

  after_commit :initialize_pin_async, :update_avatar_async, on: :create

  attr_encrypted :pin

  def mixin_api
    @mixin_api ||= MixinBot::API.new(
      client_id: uuid,
      client_secret: nil,
      session_id: session_id,
      pin_token: pin_token,
      private_key: private_key
    )
  end

  def update_pin!
    new_pin = SecureRandom.random_number.to_s.split('.').last.first(6)
    r = mixin_api.update_pin(old_pin: pin, pin: new_pin)

    raise r.inspect if r['data'].blank?

    update! pin: new_pin
  end

  def initialize_pin!
    return if pin.present?

    update_pin!
  end

  def sync_profile!
    r = mixin_api.read_me

    raise r.inspect if r['data'].blank?

    update! raw: r['data']
  end

  def initialize_pin_async
    MixinNetworkUserInitializePinWorker.perform_async id
  end

  def update_avatar
    img = File.open DEFAULT_AVATAR_FILE
    r = mixin_api.update_me(
      full_name: default_name,
      avatar_base64: Base64.strict_encode64(img.read)
    )
    update raw: r['data'] if r['data'].present?
  ensure
    img.close
  end

  def update_name
    r = mixin_api.update_me(
      full_name: default_name
    )
    update name: r['data']['full_name'], raw: r['data'] if r['data'].present?
  end

  def update_avatar_async
    MixinNetworkUserUpdateAvatarWorker.perform_async id
  end

  def default_name
    Settings.broker_name || 'PRSDigg Broker'
  end

  private

  def setup_attributes
    return unless new_record?

    r = PrsdiggBot.api.create_user(name || default_name, key_type: 'Ed25519')
    raise r.inspect if r['error'].present?

    self.raw = r['data']

    assign_attributes(
      uuid: raw['user_id'],
      name: raw['full_name'],
      pin_token: raw['pin_token'],
      session_id: raw['session_id'],
      private_key: r[:ed25519_key]&.[](:private_key)
    )
  end
end
