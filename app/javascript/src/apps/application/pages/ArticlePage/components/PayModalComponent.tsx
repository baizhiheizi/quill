import { useUserAgent } from '@application/shared';
import { usePaymentLazyQuery, useSwapPreOrderQuery } from '@graphql';
import { PRS, SUPPORTED_TOKENS } from '@shared';
import { Avatar, Button, message, Modal, Radio, Space, Spin } from 'antd';
import { encode as encode64 } from 'js-base64';
import QRCode from 'qrcode.react';
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import './PayModalComponent.less';

export default function PayModalComponent(props: {
  visible: boolean;
  price: number;
  walletId: string;
  articleUuid: string;
  paymentTraceId: string;
  onCancel: () => any;
}) {
  const {
    visible,
    price,
    walletId,
    articleUuid,
    paymentTraceId,
    onCancel,
  } = props;
  const [assetId, setAssetId] = useState(PRS.assetId);
  const [paying, setPaying] = useState(false);
  const { mixinEnv } = useUserAgent();
  const { t } = useTranslation();
  const [pollPayment, { stopPolling, data: paymentData }] = usePaymentLazyQuery(
    {
      pollInterval: 1000,
      variables: { traceId: paymentTraceId },
    },
  );
  const { loading, data } = useSwapPreOrderQuery({
    fetchPolicy: 'network-only',
    notifyOnNetworkStatusChange: true,
    variables: { payAssetId: assetId, amount: price },
  });
  const handlePaying = () => {
    setPaying(true);
    pollPayment();
  };
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
        <Button type='primary' loading={paying} onClick={handlePaying}>
          {paying ? t('articlePage.pollingPayment') : 'Paid'}
        </Button>
      </div>
    </div>
  );
  const payAmount =
    token.symbol === 'PRS' ? price.toFixed(8) : funds?.toFixed(8);
  const payUrl = `mixin://pay?recipient=${walletId}&trace=${paymentTraceId}&memo=${memo}&asset=${assetId}&amount=${payAmount}`;

  useEffect(() => {
    return () => stopPolling && stopPolling();
  }, [pollPayment, stopPolling]);

  const payment = paymentData?.payment;
  if (payment?.state === 'completed') {
    stopPolling();
    onCancel();
  } else if (payment?.state === 'refunded') {
    stopPolling();
    setPaying(false);
    message.warn('Failed. Payment refunded.');
  }

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
          <div style={{ textAlign: 'center' }}>
            <div style={{ marginBottom: '1rem' }}>
              <Space>
                <span style={{ color: 'red', fontWeight: 'bold' }}>
                  {payAmount}
                </span>
                <span>{token.symbol}</span>
              </Space>
            </div>
            <div>
              {mixinEnv ? (
                <Button
                  disabled={loading}
                  loading={paying}
                  href={payUrl}
                  onClick={handlePaying}
                  type='primary'
                >
                  {paying ? t('articlePage.pollingPayment') : 'Pay'}
                </Button>
              ) : (
                <PayUrlQRCode url={payUrl} />
              )}
            </div>
            <div>
              <Button
                type='link'
                onClick={() => {
                  if (paying) {
                    setPaying(false);
                    stopPolling && stopPolling();
                  } else {
                    setPaying(false);
                    onCancel();
                  }
                }}
              >
                {t('common.cancelBtn')}
              </Button>
            </div>
          </div>
        )}
      </div>
    </Modal>
  );
}
