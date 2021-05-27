# frozen_string_literal: true

module Prs
  # Apis interate with PRESSOne chain
  class API
    attr_reader :client, :prs_atm

    def initialize(dependencies_path = Rails.application.root.join('node_modules'))
      @prs_atm = PrsAtmSchmoozer.new dependencies_path
      @client = Client.new
    end

    def create_keystore(password = nil)
      prs_atm.create_keystore password || Rails.application.credentials.dig(:prs, :account_keystore_password)
    end

    # rep = {
    #   privatekey: '5K9CQYSu*****',
    #   publickey: 'EOS739G9******'
    # }
    def recover_private_key(keystore, password: nil)
      r = prs_atm.recover_private_key(
        (password || Rails.application.credentials.dig(:prs, :account_keystore_password)),
        keystore
      )
      r['privatekey']
    end

    delegate :open_free_account, to: :prs_atm

    delegate :hash, to: :prs_atm

    def sign(payload, user)
      Timeout.timeout(600) do
        prs_atm.sign(
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
    end

    def pip2001_authorization(count: 50, updated_at: Time.new(2021, 1, 1).rfc3339)
      path = "api/pip2001/#{Rails.application.credentials.dig(:prs, :account)}/authorization"
      client.get(
        path,
        params: {
          count: count,
          updated_at: updated_at
        }
      )
    end

    def pip2001_posts(topic = nil, count: 50, updated_at: Time.new(2021, 1, 1).rfc3339)
      path = 'api/pip2001'
      topic ||= Rails.application.credentials.dig(:prs, :account)
      client.get(
        path,
        params: {
          topic: topic,
          count: count,
          updated_at: updated_at
        }
      )
    end

    def pip2001_encrypt(content, session_id)
      hash64 = FNV.new.fnv1a_64(Rails.application.credentials.dig(:prs, :aes_256_cbc, :iv_prefix) + session_id).to_s(16).rjust(16, '0')
      cipher_iv = [hash64 + hash64].pack('H*')
      cipher_key = [Rails.application.credentials.dig(:prs, :aes_256_cbc, :key)].pack('H*')

      cipher = OpenSSL::Cipher.new 'AES-256-CBC'
      cipher.encrypt
      cipher.key = cipher_key
      cipher.iv = cipher_iv

      encrypted = cipher.update content
      encrypted << cipher.final

      {
        session: session_id,
        content: encrypted.unpack1('H*')
      }.to_json
    end
  end
end
