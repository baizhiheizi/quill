import { usePaymentLazyQuery } from '@graphql';
import {
  FOXSWAP_APP_ID,
  FOXSWAP_CODE_ID,
  FOXSWAP_DISABLE,
  PRS,
  SUPPORTED_TOKENS,
  useUserAgent,
} from '@shared';
import { Alert, Avatar, Modal, Radio, Select, Space } from 'antd';
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
}) {
  const { articleUuid, visible, onCancel, walletId } = props;
  const { mixinEnv } = useUserAgent();
  const { t } = useTranslation();
  const [share, setShare] = useState(1);
  const [assetId, setAssetId] = useState(PRS.assetId);
  const [payUrl, setPayUrl] = useState('');
  const [paying, setPaying] = useState(false);
  const [pollPayment, { stopPolling, data }] = usePaymentLazyQuery({
    pollInterval: 1500,
  });
  const token = SUPPORTED_TOKENS.find((_token) => _token.assetId === assetId);

  const handlePaying = () => {
    const traceId = uuidv4();
    const url = `mixin://pay?recipient=${walletId}&trace=${traceId}&memo=${encode64(
      JSON.stringify({ t: 'REWARD', a: articleUuid }),
    )}&asset=${assetId}&amount=${(share * token.priceBase).toFixed(8)}`;
    if (mixinEnv) {
      location.replace(url);
    } else {
      setPayUrl(url);
    }
    setPaying(true);
    pollPayment({ variables: { traceId } });
  };

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
    </div>
  );

  useEffect(() => {
    return () => stopPolling && stopPolling();
  }, []);

  if (Boolean(data?.payment?.state)) {
    stopPolling();
  }

  return (
    <Modal
      className='reward-modal'
      centered
      closable={false}
      destroyOnClose={true}
      title={t('articlePage.rewardModal.title')}
      confirmLoading={paying && !Boolean(data?.payment?.state)}
      okText={
        Boolean(data?.payment?.state)
          ? t('articlePage.rewardModal.finishText')
          : paying
          ? t('articlePage.rewardModal.pollingPayment')
          : t('articlePage.rewardModal.okText')
      }
      cancelText={t('articlePage.rewardModal.cancelText')}
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
        style={{ marginBottom: '1rem' }}
        options={[
          { label: token.priceBase, value: 1 },
          { label: 8 * token.priceBase, value: 8 },
          { label: 32 * token.priceBase, value: 32 },
          { label: 64 * token.priceBase, value: 64 },
          { label: 256 * token.priceBase, value: 256 },
          { label: 1024 * token.priceBase, value: 1024 },
        ]}
        value={share}
        onChange={(e) => setShare(e.target.value)}
        optionType='button'
      />
      <div style={{ marginBottom: '1rem', textAlign: 'right' }}>
        <Select
          style={{ marginBottom: 5 }}
          disabled={paying}
          value={assetId}
          onSelect={(value) => setAssetId(value)}
        >
          {SUPPORTED_TOKENS.map((token) => (
            <Select.Option
              value={token.assetId}
              key={token.assetId}
              disabled={FOXSWAP_DISABLE && token.symbol !== 'PRS'}
            >
              <Space>
                <Avatar src={token.iconUrl} size='small' />
                <span>{token.symbol}</span>
              </Space>
            </Select.Option>
          ))}
        </Select>
        {token.symbol !== 'PRS' && (
          <div style={{ color: '#aaa' }}>
            {t('articlePage.rewardModal.swapExplain')}{' '}
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
        <Alert
          type='success'
          message={t('articlePage.rewardModal.successPaidMessage')}
        />
      ) : (
        !mixinEnv && paying && <PayUrlQRCode url={payUrl} />
      )}
    </Modal>
  );
}
