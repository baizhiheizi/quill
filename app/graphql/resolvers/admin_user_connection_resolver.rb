# frozen_string_literal: true

module Resolvers
  class AdminUserConnectionResolver < AdminBaseResolver
    argument :query, String, required: false
    argument :order_by, String, required: false
    argument :filter, String, required: false
    argument :after, String, required: false

    type Types::UserConnectionType, null: false

    def resolve(params = {})
      users =
        case params[:filter]
        when 'without_banned'
          User.without_banned
        when 'only_banned'
          User.only_banned
        else
          User.all
        end

      q = params[:query].to_s.strip
      q_ransack = { name_cont: q, mixin_id_cont: q }
      users = users.ransack(q_ransack.merge(m: 'or')).result

      case params[:order_by]
      when 'revenue_total'
        users.order_by_revenue_total
      when 'payment_total'
        users.order_by_payment_total
      when 'articles_count'
        users.order_by_articles_count
      when 'comments_count'
        users.order_by_comments_count
      else
        users.order(created_at: :desc)
      end
    end
  end
end
