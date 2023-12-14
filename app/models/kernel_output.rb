# frozen_string_literal: true

# == Schema Information
#
# Table name: kernel_outputs
#
#  id         :bigint           not null, primary key
#  amount     :decimal(, )
#  raw        :json
#  state      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  asset_id   :uuid
#
# Indexes
#
#  index_kernel_outputs_on_asset_id  (asset_id)
#
class KernelOutput < ApplicationRecord
  POLLING_INTERVAL = 0.1
  POLLING_LIMIT = 500

  belongs_to :currency, foreign_key: :asset_id, primary_key: :asset_id, inverse_of: :kernel_outputs, optional: true

  validates :asset_id, presence: true
  validates :amount, presence: true
  validates :state, presence: true

  scope :unspent, -> { where(state: 'unspent') }
  scope :spent, -> { where(state: 'spent') }

  before_validation :set_defaults

  def self.poll
    loop do
      offset = order(id: :desc).first&.id

      r = QuillBot.api.safe_outputs limit: 500, offset: offset, app: QuillBot.api.client_id

      r['data'].each do |raw|
        output = KernelOutput.find_or_initialize_by(id: raw['sequence'])
        output.raw = raw
        output.save!
      end

      break if r['data'].size < 500

      sleep POLLING_INTERVAL
    end
  end

  def self.select_for(asset_id, sum)
    sum = sum.to_d
    outputs = []

    unspent.where(asset_id: asset_id).order(amount: :asc).each do |output|
      break if outputs.sum(&:amount) >= sum
      break if outputs.size >= 255

      outputs << output
    end
    return outputs if outputs.sum(&:amount) >= sum

    outputs = []
    unspent.where(asset_id: asset_id).order(amount: :desc).each do |output|
      break if outputs.sum(&:amount) >= sum
      break if outputs.size >= 255

      outputs << output
    end

    return [] if outputs.sum(&:amount) < sum

    outputs
  end

  def refresh!
    r = QuillBot.api.safe_output raw['output_id']
    self.raw = r['data']
    save!
  end

  def spend!
    refresh!

    raise 'Not spent yet' unless raw['state'] == 'spent'
  end

  private

  def set_defaults
    assign_attributes(
      id: raw['sequence'],
      asset_id: raw['asset_id'],
      amount: raw['amount'],
      state: raw['state'],
      created_at: raw['created_at'],
      updated_at: raw['updated_at']
    )
  end
end
