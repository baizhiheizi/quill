# frozen_string_literal: true

module Prs
  # Apis interate with PRESSOne chain
  class API
    def initialize(dependencies_path = Rails.application.root.join('node_modules'))
      @prs_atm = PrsAtmSchmoozer.new dependencies_path
    end

    def account_keystore_password
      Rails.application.credentials.dig(:prs, :account_keystore_password)
    end

    def create_keystore(password = nil)
      @prs_atm.create_keystore password || account_keystore_password
    end

    # rep = {
    #   privatekey: '5K9CQYSu*****',
    #   publickey: 'EOS739G9******'
    # }
    def recover_private_key(keystore, password: nil)
      r = @prs_atm.recover_private_key(
        (password || account_keystore_password),
        keystore
      )
      r['privatekey']
    end

    def open_free_account(public_key, private_key)
      @prs_atm.open_free_account public_key, private_key
    end

    def hash(file_content)
      @prs_atm.hash file_content
    end

    def sign(payload, user)
      @prs_atm.sign(
        payload[:type],
        payload[:meta],
        payload[:data],
        Rails.application.credentials.dig(:prs, :account),
        Rails.application.credentials.dig(:prs, :public_key),
        Rails.application.credentials.dig(:prs, :private_key),
        {
          userAddress: user[:account],
          privateKey: user[:private_key]
        }
      )
    end

    def pip2001_authorization
    end

    def pip2001_posts
    end
  end
end
