# frozen_string_literal: true

module Users::Statable
  extend ActiveSupport::Concern

  def unread_notifications_count
    notifications.unread.count
  end

  def has_unread_notification?
    notifications.unread.present?
  end

  def articles_count
    @articles_count ||= articles.count
  end

  def bought_articles_count
    @bought_articles_count ||= bought_articles.count
  end

  def comments_count
    @comments_count ||= comments.count
  end

  def payment_total_usd
    @payment_total_usd ||= orders.sum(:value_usd).to_f
  end

  def author_revenue_total_usd
    @author_revenue_total_usd ||= transfers.joins(:currency).where(transfer_type: :author_revenue).sum('amount * currencies.price_usd').to_f
  end

  def reader_revenue_total_usd
    @reader_revenue_total_usd ||= transfers.joins(:currency).where(transfer_type: :reader_revenue).sum('amount * currencies.price_usd').to_f
  end

  def revenue_total_usd
    @revenue_total_usd ||= transfers.joins(:currency).where(transfer_type: %i[author_revenue reader_revenue]).sum('amount * currencies.price_usd').to_f
  end

  def validated?
    validated_at?
  end

  def validate!
    update validated_at: Time.current
  end

  def unvalidate!
    update validated_at: nil
  end

  def fennec?
    authorization.provider == 'fennec'
  end

  def messenger?
    authorization.provider == 'mixin'
  end

  def mvm_eth?
    authorization.provider == 'mvm_eth'
  end

  def accessable?
    return true unless Settings.whitelist&.enable

    mixin_id_in_whitelist? || phone_country_code_in_whitelist?
  end

  def mixin_id_in_whitelist?
    mixin_id.in? (Settings.whitelist&.mixin_id || []).map(&:to_s)
  end

  def phone_country_code_in_whitelist?
    Regexp.new("^\\+?(#{Settings.whitelist&.phone_country_code&.join('|')})\\d+").match? phone
  end

  def may_claim_faucet?
    return unless mvm_eth?

    faucet_bonus.blank?
  end

  def claim_faucet!
    return unless may_claim_faucet?

    deposit = authorization.mixin_api.snapshots['data'].find(&->(snapshot) { snapshot['type'] == 'deposit' })
    return if deposit.blank?

    deposit_asset = Currency.find_or_create_by asset_id: deposit['asset_id']
    bonus =
      bonuses.create!(
        asset_id: Currency::XIN_ASSET_ID,
        title: 'Faucet',
        description: "Desposited #{deposit['amount']} #{deposit_asset.symbol}",
        amount: Bonus::XIN_FAUCET_AMOUNT
      )
    bonus.deliver!
  end

  def faucet_bonus
    @faucet_bonus = bonuses.find_by(asset_id: Currency::XIN_ASSET_ID, title: 'Faucet')
  end
end