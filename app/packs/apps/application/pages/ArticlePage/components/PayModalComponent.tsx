import { Currency, usePaymentLazyQuery, useSwapPreOrderQuery } from '@graphql';
import {
  FOXSWAP_APP_ID,
  FOXSWAP_CODE_ID,
  useCurrentUser,
  useUserAgent,
} from '@shared';
import { useCountDown } from 'ahooks';
import { Alert, Avatar, Button, Modal, Radio, Space, Spin } from 'antd';
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
  articleAssetId: string;
  paymentTraceId: string;
  swappableCurrencies: Currency[];
  onCancel: () => any;
}) {
  const {
    visible,
    price,
    walletId,
    articleUuid,
    articleAssetId,
    paymentTraceId,
    swappableCurrencies,
    onCancel,
  } = props;
  const { currentUser } = useCurrentUser();
  const [assetId, setAssetId] = useState(articleAssetId);
  const [paying, setPaying] = useState(false);
  const { mixinEnv } = useUserAgent();
  const { t } = useTranslation();
  const [countdown, setTargetDate] = useCountDown();
  const [pollPayment, { stopPolling, data: paymentData }] = usePaymentLazyQuery(
    {
      pollInterval: 1500,
      variables: { traceId: paymentTraceId },
    },
  );
  const payment = paymentData?.payment;
  const { loading: preOrderLoading, data: preOrderData } = useSwapPreOrderQuery(
    {
      fetchPolicy: 'network-only',
      notifyOnNetworkStatusChange: true,
      variables: {
        payAssetId: assetId,
        fillAssetId: articleAssetId,
        amount: price * 1.01,
      },
    },
  );
  const handlePaying = () => {
    setPaying(true);
    setTargetDate(Date.now() + 60000);
    pollPayment();
  };
  const memo = encode64(
    JSON.stringify({
      t: 'BUY',
      a: articleUuid,
      p: price,
    }),
  );
  const currency = swappableCurrencies.find(
    (_currency: Currency) => _currency.assetId === assetId,
  );
  const funds = preOrderData?.swapPreOrder?.funds;
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
          {paying
            ? `${Math.round(countdown / 1000)} s ${t(
                'articlePage.payModal.pollingPayment',
              )}`
            : t('articlePage.payModal.checkPaymentBtn')}
        </Button>
      </div>
    </div>
  );
  const payAmount =
    currency.assetId === articleAssetId ? price.toFixed(8) : funds?.toFixed(8);
  const payUrl = `mixin://pay?recipient=${
    currentUser?.walletId || walletId
  }&trace=${paymentTraceId}&memo=${memo}&asset=${assetId}&amount=${payAmount}`;

  useEffect(() => {
    return () => stopPolling && stopPolling();
  }, [pollPayment, stopPolling]);

  if (payment?.state === 'completed') {
    stopPolling();
    onCancel();
  } else if (payment?.state === 'refunded') {
    stopPolling();
  }

  return (
    <Modal
      className='pay-modal'
      title={t('articlePage.payModal.title')}
      centered
      closable={false}
      destroyOnClose={true}
      maskClosable={false}
      visible={visible}
      footer={null}
      onCancel={onCancel}
    >
      <div style={{ maxWidth: 380, margin: 'auto' }}>
        <div style={{ marginBottom: '1rem' }}>
          <Radio.Group
            value={assetId}
            onChange={(e) => setAssetId(e.target.value)}
            disabled={paying}
          >
            {swappableCurrencies.map((_currency: Currency) => (
              <Radio.Button key={_currency.assetId} value={_currency.assetId}>
                <Space>
                  <Avatar size='small' src={_currency.iconUrl} />
                  <span>{_currency.symbol}</span>
                </Space>
              </Radio.Button>
            ))}
          </Radio.Group>
        </div>
        {preOrderLoading ? (
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
                <span>{currency.symbol}</span>
              </Space>
              {currency.assetId !== articleAssetId && (
                <div style={{ color: '#aaa' }}>
                  {t('articlePage.payModal.swapExplain')}{' '}
                  <a
                    href={
                      mixinEnv
                        ? `mixin://users/${FOXSWAP_APP_ID}`
                        : `https://mixin.one/codes/${FOXSWAP_CODE_ID}`
                    }
                    target='_blank'
                  >
                    4swap
                  </a>
                </div>
              )}
            </div>
            {payment?.state === 'refunded' ? (
              <Alert
                message={t('articlePage.payModal.refundWarning')}
                showIcon
                type='warning'
              />
            ) : (
              <div>
                {mixinEnv ? (
                  <Button
                    disabled={preOrderLoading || payment?.state === 'refunded'}
                    loading={paying}
                    href={payUrl}
                    onClick={handlePaying}
                    type='primary'
                  >
                    {paying
                      ? `${Math.round(countdown / 1000)} s ${t(
                          'articlePage.payModal.pollingPayment',
                        )}`
                      : t('articlePage.payModal.payBtn')}
                  </Button>
                ) : (
                  <PayUrlQRCode url={payUrl} />
                )}
              </div>
            )}
            <div>
              <Button
                type='link'
                onClick={() => {
                  if (paying && payment?.state !== 'refunded') {
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
