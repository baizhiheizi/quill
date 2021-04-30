# frozen_string_literal: true

# == Schema Information
#
# Table name: prs_accounts
#
#  id                    :bigint           not null, primary key
#  account               :string
#  encrypted_private_key :string
#  keystore              :jsonb
#  public_key            :string
#  status                :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  user_id               :bigint
#
# Indexes
#
#  index_prs_accounts_on_account  (account) UNIQUE
#  index_prs_accounts_on_user_id  (user_id)
#
class PrsAccount < ApplicationRecord
  include Encryptable
  include AASM

  attr_encrypted :private_key

  belongs_to :user

  has_many :transactions, class_name: 'PrsTransaction', primary_key: :account,\
                          foreign_key: :user_address, inverse_of: :prs_account,\
                          dependent: :restrict_with_error

  validates :keystore, presence: true
  validates :public_key, presence: true
  validates :private_key, presence: true

  before_validation :set_defaults, on: :create

  after_commit on: :create do
    register_on_chain_async
  end

  aasm column: :status do
    state :created, initial: true
    state :registered
    state :allowed
    state :denied

    event :register, after_commit: :allow_on_chain_async do
      transitions from: :created, to: :registered
    end

    event :allow do
      transitions from: :registered, to: :allowed
      transitions from: :denied, to: :allowed
    end

    event :deny do
      transitions from: :allowed, to: :denied
    end
  end

  def allow_on_chain!
    return if user.banned?
    return if allowed?

    r =
      Prs.api.sign(
        {
          type: 'PIP:2001',
          meta: {},
          data: {
            allow: account,
            topic: Rails.application.credentials.dig(:prs, :account)
          }
        },
        {
          account: Rails.application.credentials.dig(:prs, :account),
          private_key: Rails.application.credentials.dig(:prs, :private_key)
        }
      )
    ActiveRecord::Base.transaction do
      block = r['processed']['action_traces'].first['act']['data']
      PrsAccountAllowTransaction
        .create_with(raw: block)
        .find_or_create_by!(transation_id: r['transaction_id'])
      allow!
    end
  end

  def allow_on_chain_async
    PrsAccountAllowOnChainWorker.perform_async id
  end

  def deny_on_chain!
    return unless allowed?

    r =
      Prs.api.sign(
        {
          type: 'PIP:2001',
          meta: {},
          data: {
            deny: account,
            topic: Rails.application.credentials.dig(:prs, :account)
          }
        },
        {
          account: Rails.application.credentials.dig(:prs, :account),
          private_key: Rails.application.credentials.dig(:prs, :private_key)
        }
      )
    ActiveRecord::Base.transaction do
      block = r['processed']['action_traces'][0]['act']['data']
      PrsAccountDenyTransaction
        .create_with(raw: block)
        .find_or_create_by!(transation_id: r['transaction_id'])
      deny!
    end
  end

  def deny_on_chain_async
    PrsAccountDenyOnChainWorker.perform_async id
  end

  def register_on_chain!
    r = Prs.api.open_free_account public_key, private_key
    update! account: r['account']
    register!
  end

  def register_on_chain_async
    PrsAccountRegisterOnChainWorker.perform_async id
  end

  private

  def set_defaults
    return unless new_record?

    keystore = Prs.api.create_keystore
    private_key = Prs.api.recover_private_key keystore
    assign_attributes(
      keystore: keystore,
      public_key: keystore['publickey'],
      private_key: private_key
    )
  end
end
