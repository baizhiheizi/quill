import { useSwapPreOrderQuery } from '@/graphql';
import { useUserAgent } from '@application/shared';
import { PRS, SUPPORTED_TOKENS } from '@shared';
import { Avatar, Button, Modal, Radio, Space, Spin } from 'antd';
import { encode as encode64 } from 'js-base64';
import QRCode from 'qrcode.react';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { v4 as uuidv4 } from 'uuid';
import './PayModalComponent.less';

export default function PayModalComponent(props: {
  visible: boolean;
  price: number;
  walletId: string;
  articleUuid: string;
  onCancel: () => any;
}) {
  const { visible, price, walletId, articleUuid, onCancel } = props;
  const [assetId, setAssetId] = useState(PRS.assetId);
  const [paying, setPaying] = useState(false);
  const { mixinEnv } = useUserAgent();
  const { t } = useTranslation();
  const { loading, data } = useSwapPreOrderQuery({
    fetchPolicy: 'network-only',
    notifyOnNetworkStatusChange: true,
    variables: { payAssetId: assetId, amount: price },
  });
  const memo = encode64(
    JSON.stringify({
      t: 'BUY',
      a: articleUuid,
      p: price,
    }),
  );
  const token = SUPPORTED_TOKENS.find((token) => token.assetId === assetId);
  const funds = data?.swapPreOrder?.funds;
  const PayUrlQRCode = ({ url, type = 'pay' }) => (
    <div style={{ textAlign: 'center' }}>
      <div style={{ marginBottom: 5 }}>
        <QRCode value={url} size={200} />
      </div>
      <div style={{ color: '#aaa', marginBottom: 5 }}>
        {type === 'pay'
          ? t('messages.payWithMessenger')
          : t('messages.viewWithMessenger')}
      </div>
      <div>
        <Button type='primary' loading={paying} onClick={() => setPaying(true)}>
          Paid
        </Button>
      </div>
    </div>
  );
  const payAmount =
    token.symbol === 'PRS' ? price.toFixed(8) : funds?.toFixed(8);
  const payUrl = `mixin://pay?recipient=${walletId}&trace=${uuidv4()}&memo=${memo}&asset=${assetId}&amount=${payAmount}`;

  return (
    <Modal
      className='pay-modal'
      title='Buy Article'
      closable
      visible={visible}
      footer={null}
      onCancel={onCancel}
    >
      <div style={{ maxWidth: 380, margin: 'auto' }}>
        <div style={{ marginBottom: '1rem' }}>
          <Radio.Group
            value={assetId}
            onChange={(e) => setAssetId(e.target.value)}
          >
            {SUPPORTED_TOKENS.map((token) => (
              <Radio.Button key={token.assetId} value={token.assetId}>
                <Space>
                  <Avatar size='small' src={token.iconUrl} />
                  <span>{token.symbol}</span>
                </Space>
              </Radio.Button>
            ))}
          </Radio.Group>
        </div>
        {loading ? (
          <div style={{ textAlign: 'center' }}>
            <Spin />
          </div>
        ) : (
          <div>
            <div style={{ textAlign: 'center', marginBottom: '1rem' }}>
              <Space>
                <span style={{ color: 'red', fontWeight: 'bold' }}>
                  {payAmount}
                </span>
                <span>{token.symbol}</span>
              </Space>
            </div>
            <div style={{ textAlign: 'center' }}>
              {mixinEnv ? (
                <Button
                  disabled={loading || paying}
                  loading={paying}
                  href={payUrl}
                  onClick={() => setPaying(true)}
                  type='primary'
                >
                  Pay
                </Button>
              ) : (
                <PayUrlQRCode url={payUrl} />
              )}
            </div>
          </div>
        )}
      </div>
    </Modal>
  );
}
