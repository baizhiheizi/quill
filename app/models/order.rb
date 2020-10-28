# frozen_string_literal: true

# == Schema Information
#
# Table name: orders
#
#  id          :bigint           not null, primary key
#  item_type   :string
#  order_type  :integer
#  state       :string
#  total       :decimal(, )
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  item_id     :bigint
#  payer_id    :bigint
#  receiver_id :bigint
#  trace_id    :uuid
#
# Indexes
#
#  index_orders_on_item_type_and_item_id  (item_type,item_id)
#  index_orders_on_payer_id               (payer_id)
#  index_orders_on_receiver_id            (receiver_id)
#
class Order < ApplicationRecord
  AUTHOR_RATIO = 0.5
  READER_RATIO = 0.4
  PRSDIGG_RATIO = 0.1

  include AASM

  belongs_to :payer, class_name: 'User'
  belongs_to :receiver, class_name: 'User'
  belongs_to :item, polymorphic: true

  has_many :transfers, as: :source, dependent: :nullify
  has_one :payment, foreign_key: :trace_id, primary_key: :trace_id, dependent: :nullify, inverse_of: :order

  before_validation :setup_attributes

  validate :ensure_total_sufficient

  enum order_type: { buy_article: 0, reward_article: 1 }

  after_create :complete_payment, :create_transfers

  aasm column: :state do
    state :paid, initial: true
    state :complete

    event :complete, guard: :all_transfers_processed? do
      transitions from: :paid, to: :complete
    end
  end

  # core logic
  # transfer revenue to author and readers
  def create_transfers
    create_author_transfer
    create_reader_transfers
  end

  def create_author_revenue_transfer
    create_transfers!(
      transfer_type: :author_revenue,
      amount: (total * AUTHOR_RATIO).round(8),
      opponent_id: item.author.mixin_uuid,
      asset_id: payment.asset_id,
      memo: "#{payer.name} paid for your article"
    )
  end

  def create_reader_revenue_transfers
    # TODO: based on the order records before
    # amount = totle * READER_RATIO
  end

  def all_transfers_processed?
    transfers.unprocessed.blank?
  end

  def complete_payment
    payment.complete
  end

  def ensure_total_sufficient
    errors.add(total: 'Wrong token!') unless payment.asset_id == item.asset_id
    errors.add(:total, 'amount not sufficient') unless total >= item.price
  end

  private

  def setup_attributes
    assign_attributes(
      payer: payment.payer,
      receiver: item.author,
      total: payment.amount
    )
  end
end
