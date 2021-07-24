import { Modal, Spin } from 'antd';
import { imagePath, usePrsdigg } from 'apps/shared';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';

export default function LoginModalComponent(props: { children: JSX.Element }) {
  const { children } = props;
  const { t } = useTranslation();
  const [visible, setVisible] = useState(false);
  const [loading, setLoading] = useState(false);
  const { messenger } = usePrsdigg();

  return (
    <>
      {React.cloneElement(children, { onClick: () => setVisible(true) })}
      <Modal
        title={t('connect_wallet')}
        centered
        maskClosable
        visible={visible}
        onCancel={() => {
          setVisible(false);
          setLoading(false);
        }}
        footer={null}
      >
        <Spin spinning={loading}>
          <div
            className='flex items-center justify-center w-full py-2 text-lg bg-gray-100 cursor-pointer rounded-md space-x-2'
            onClick={() => {
              setLoading(true);
              location.replace(
                `/login?return_to=${encodeURIComponent(location.href)}`,
              );
            }}
          >
            {messenger === 'mixin' ? (
              <>
                <img className='w-10 h-10' src={imagePath('mixin-logo.png')} />
                <span>Mixin Messenger</span>
              </>
            ) : (
              <img className='h-10' src={imagePath('links-logo.png')} />
            )}
          </div>
        </Spin>
      </Modal>
    </>
  );
}
