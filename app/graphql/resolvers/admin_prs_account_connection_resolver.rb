# frozen_string_literal: true

module Resolvers
  class AdminPrsAccountConnectionResolver < AdminBaseResolver
    argument :query, String, required: false
    argument :status, String, required: false
    argument :after, String, required: false

    type Types::PrsAccountType.connection_type, null: false

    def resolve(**params)
      prs_accounts =
        case params[:status].to_sym
        when :created
          PrsAccount.created
        when :registered
          PrsAccount.registered
        when :allowing
          PrsAccount.allowing
        when :allowed
          PrsAccount.allowed
        when :denying
          PrsAccount.denying
        when :denied
          PrsAccount.denied
        else
          PrsAccount.all
        end

      q = params[:query].to_s.strip
      q_ransack = { account_cont: q, user_name_cont: q, user_mixin_id_cont: q }

      prs_accounts = prs_accounts.includes(:user).ransack(q_ransack.merge(m: 'or')).result

      prs_accounts.order(created_at: :desc)
    end
  end
end
