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
#  request_allow_at      :datetime
#  request_denny_at      :datetime
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

  delegate :present?, to: :account, prefix: true

  aasm column: :status do
    state :created, initial: true
    state :registered
    state :allowing
    state :allowed
    state :denying
    state :denied

    event :register, guards: %i[account_present?], after_commit: :allow_on_chain_async do
      transitions from: :created, to: :registered
    end

    event :request_allow, guards: %i[request_allow_timeout?], after_commit: %i[touch_request_allow_at] do
      transitions from: :registered, to: :allowing
      transitions from: :denied, to: :allowing
    end

    event :allow, guards: %i[user_not_banned] do
      transitions from: :registered, to: :allowed
      transitions from: :denied, to: :allowed
      transitions from: :allowing, to: :allowed
    end

    event :request_deny, guards: %i[request_deny_timeout?], after_commit: %i[touch_request_denny_at] do
      transitions from: :allowed, to: :denying
    end

    event :deny do
      transitions from: :denying, to: :denied
      transitions from: :allowed, to: :denied
    end
  end

  def allow_on_chain!
    return unless may_allow?
    return unless request_allow_timeout?

    r = Prs.api.sign(
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

    raise r.inspect if r['processed']['action_traces'][0]['act']['data']['id'].blank?

    request_allow! if may_request_allow?
    touch_request_allow_at
  end

  def allow_on_chain_async
    PrsAccountAllowOnChainWorker.perform_async id
  end

  def deny_on_chain!
    return unless may_deny?
    return unless request_deny_timeout?

    r = Prs.api.sign(
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

    raise r.inspect if r['processed']['action_traces'][0]['act']['data']['id'].blank?

    request_deny! if may_request_deny?
    touch_request_denny_at
  end

  def deny_on_chain_async
    PrsAccountDenyOnChainWorker.perform_async id
  end

  def register_on_chain!
    return unless created?

    r = Prs.api.open_free_account public_key, private_key

    ActiveRecord::Base.transaction do
      update! account: r['account']
      register!
    end
  end

  def register_on_chain_async
    PrsAccountRegisterOnChainWorker.perform_async id
  end

  def request_allow_timeout?
    return true unless allowing? && request_allow_at?

    Time.current - request_allow_at > 30.minutes
  end

  def request_deny_timeout?
    return true unless denying? && request_deny_at?

    Time.current - request_deny_at > 30.minutes
  end

  def touch_request_allow_at
    update request_allow_at: Time.current
  end

  def touch_request_denny_at
    update request_denny_at: Time.current
  end

  def user_not_banned
    !user.banned?
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
