import { Alert, Avatar, Modal, Radio, Select, Space } from 'antd';
import {
  FOXSWAP_APP_ID,
  FOXSWAP_CODE_ID,
  useCurrentUser,
  useUserAgent,
} from 'apps/shared';
import { Currency, usePaymentLazyQuery } from 'graphqlTypes';
import { encode as encode64 } from 'js-base64';
import QRCode from 'qrcode.react';
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { v4 as uuidv4 } from 'uuid';
import './RewardModalComponent.less';

export default function RewardModalComponent(props: {
  visible: boolean;
  onCancel: () => any;
  walletId: string;
  articleUuid: string;
  articleAssetId: string;
  swappableCurrencies: Currency[];
}) {
  const { currentUser } = useCurrentUser();
  const {
    articleUuid,
    articleAssetId,
    visible,
    onCancel,
    walletId,
    swappableCurrencies,
  } = props;
  const { mixinEnv } = useUserAgent();
  const { t } = useTranslation();
  const [share, setShare] = useState(1);
  const [assetId, setAssetId] = useState(articleAssetId);
  const [payUrl, setPayUrl] = useState('');
  const [paying, setPaying] = useState(false);
  const [pollPayment, { stopPolling, data }] = usePaymentLazyQuery({
    pollInterval: 1500,
  });

  useEffect(() => {
    return () => stopPolling && stopPolling();
  }, []);

  if (Boolean(data?.payment?.state)) {
    stopPolling();
  }

  const priceBaseUsd = 0.1;
  const currency = swappableCurrencies.find(
    (_currency) => _currency.assetId == assetId,
  );

  const handlePaying = () => {
    const traceId = uuidv4();
    const url = `mixin://pay?recipient=${
      currentUser?.walletId || walletId
    }&trace=${traceId}&memo=${encode64(
      JSON.stringify({ t: 'REWARD', a: articleUuid }),
    )}&asset=${assetId}&amount=${(
      share *
      (priceBaseUsd / currency.priceUsd)
    ).toFixed(8)}`;
    if (mixinEnv) {
      location.replace(url);
    } else {
      setPayUrl(url);
    }
    setPaying(true);
    pollPayment({ variables: { traceId } });
  };

  const PayUrlQRCode = ({ url, type = 'pay' }) => (
    <div className='mb-2'>
      <div className='flex justify-center mb-2'>
        <QRCode value={url} size={200} />
      </div>
      <div className='mb-2 text-center text-gray-500'>
        {type === 'pay' ? t('pay_with_messenger') : t('view_with_messenger')}
      </div>
    </div>
  );

  return (
    <Modal
      className='reward-modal'
      centered
      closable={false}
      destroyOnClose={true}
      title={t('reward')}
      confirmLoading={paying && !Boolean(data?.payment?.state)}
      okText={
        Boolean(data?.payment?.state)
          ? t('finish')
          : paying
          ? t('polling_payment')
          : t('reward')
      }
      cancelText={t('later')}
      visible={visible}
      onCancel={() => {
        stopPolling && stopPolling();
        onCancel();
      }}
      onOk={() => {
        if (Boolean(data?.payment?.state)) {
          onCancel();
        } else if (!paying) {
          handlePaying();
        }
      }}
    >
      <Radio.Group
        disabled={paying}
        className='mb-4'
        options={[
          { label: (priceBaseUsd / currency.priceUsd).toFixed(6), value: 1 },
          {
            label: ((8 * priceBaseUsd) / currency.priceUsd).toFixed(6),
            value: 8,
          },
          {
            label: ((32 * priceBaseUsd) / currency.priceUsd).toFixed(6),
            value: 32,
          },
          {
            label: ((64 * priceBaseUsd) / currency.priceUsd).toFixed(6),
            value: 64,
          },
          {
            label: ((256 * priceBaseUsd) / currency.priceUsd).toFixed(6),
            value: 256,
          },
          {
            label: ((1024 * priceBaseUsd) / currency.priceUsd).toFixed(6),
            value: 1024,
          },
        ]}
        value={share}
        onChange={(e) => setShare(e.target.value)}
        optionType='button'
      />
      <div className='mb-4 text-right'>
        <Select
          style={{ marginBottom: 5 }}
          disabled={paying}
          value={assetId}
          onSelect={(value) => setAssetId(value)}
        >
          {swappableCurrencies.map((_currency) => (
            <Select.Option value={_currency.assetId} key={_currency.assetId}>
              <Space>
                <Avatar src={_currency.iconUrl} size='small' />
                <span>{_currency.symbol}</span>
              </Space>
            </Select.Option>
          ))}
        </Select>
        {currency.assetId !== articleAssetId && (
          <div style={{ color: '#aaa' }}>
            {t('swap_supported_by')}{' '}
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
      {Boolean(data?.payment?.state) ? (
        <Alert type='success' message={t('success_paid')} />
      ) : (
        !mixinEnv && paying && <PayUrlQRCode url={payUrl} />
      )}
    </Modal>
  );
}
