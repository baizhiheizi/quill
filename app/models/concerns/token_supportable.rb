# frozen_string_literal: true

module TokenSupportable
  SUPPORTED_TOKENS = [
    {
      asset_id: '3edb734c-6d6f-32ff-ab03-4eb43640c758',
      icon_url:
        'https://mixin-images.zeromesh.net/1fQiAdit_Ji6_Pf4tW8uzutONh9kurHhAnN4wqEIItkDAvFTSXTMwlk3AB749keufDFVoqJb5fSbgz7K2HoOV7Q=s128',
      name: 'PressOne Token',
      symbol: 'PRS'
    },
    {
      asset_id: '3edb734c-6d6f-32ff-ab03-4eb43640c758',
      icon_url:
        'https://mixin-images.zeromesh.net/1fQiAdit_Ji6_Pf4tW8uzutONh9kurHhAnN4wqEIItkDAvFTSXTMwlk3AB749keufDFVoqJb5fSbgz7K2HoOV7Q=s128',
      name: 'PressOne Token',
      symbol: 'PRS'
    },
    {
      asset_id: 'c6d0c728-2624-429b-8e0d-d9d19b6592fa',
      icon_url:
        'https://mixin-images.zeromesh.net/HvYGJsV5TGeZ-X9Ek3FEQohQZ3fE9LBEBGcOcn4c4BNHovP4fW4YB97Dg5LcXoQ1hUjMEgjbl1DPlKg1TW7kK6XP=s128',
      name: 'Bitcoin',
      symbol: 'BTC'
    },
    {
      asset_id: '6cfe566e-4aad-470b-8c9a-2fd35b49c68d',
      icon_url:
        'https://mixin-images.zeromesh.net/a5dtG-IAg2IO0Zm4HxqJoQjfz-5nf1HWZ0teCyOnReMd3pmB8oEdSAXWvFHt2AJkJj5YgfyceTACjGmXnI-VyRo=s128',
      name: 'EOS',
      symbol: 'EOS'
    },
    {
      asset_id: '43d61dcd-e413-450d-80b8-101d5e903357',
      icon_url:
        'https://mixin-images.zeromesh.net/zVDjOxNTQvVsA8h2B4ZVxuHoCF3DJszufYKWpd9duXUSbSapoZadC7_13cnWBqg0EmwmRcKGbJaUpA8wFfpgZA=s128',
      name: 'ETH',
      symbol: 'ETH'
    },
    {
      asset_id: '4d8c508b-91c5-375b-92b0-ee702ed2dac5',
      icon_url:
        'https://mixin-images.zeromesh.net/ndNBEpObYs7450U08oAOMnSEPzN66SL8Mh-f2pPWBDeWaKbXTPUIdrZph7yj8Z93Rl8uZ16m7Qjz-E-9JFKSsJ-F=s128',
      name: 'Tether USD',
      symbol: 'USDT'
    },
    {
      asset_id: 'c94ac88f-4671-3976-b60a-09064f1811e8',
      icon_url:
        'https://mixin-images.zeromesh.net/UasWtBZO0TZyLTLCFQjvE_UYekjC7eHCuT_9_52ZpzmCC-X-NPioVegng7Hfx0XmIUavZgz5UL-HIgPCBECc-Ws=s128',
      name: 'Mixin',
      symbol: 'XIN'
    }
  ].freeze

  extend ActiveSupport::Concern

  def token_supported?
    token.present?
  end

  def token
    SUPPORTED_TOKENS.find(&->(token) { token[:asset_id] == asset_id })
  end
end
