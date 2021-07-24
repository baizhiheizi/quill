import { MenuOutlined } from '@ant-design/icons';
import { Left as LeftIcon } from '@icon-park/react';
import { Avatar, Button, Drawer, Layout } from 'antd';
import {
  imagePath,
  useCurrentUser,
  usePrsdigg,
  useUserAgent,
} from 'apps/shared';
import { useSwitchLocaleMutation } from 'graphqlTypes';
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useHistory } from 'react-router-dom';
import MenuComponent from '../MenuComponent/MenuComponent';

export default function HeaderComponent() {
  const history = useHistory();
  const { logoFile } = usePrsdigg();
  const { mixinEnv, isMobile } = useUserAgent();
  const { t, i18n } = useTranslation();
  const [drawerVisible, setDrawerVisible] = useState(false);
  const { currentUser } = useCurrentUser();
  const [switchLocale] = useSwitchLocaleMutation();
  const [showBack, setShowBack] = useState(location.pathname !== '/');

  useEffect(() => {
    setShowBack(location.pathname !== '/');
  }, [location.pathname]);

  useEffect(() => {
    if (!currentUser) {
      return;
    }
    if (currentUser.locale !== i18n.language) {
      switchLocale({ variables: { input: { locale: i18n.language } } });
    }
    i18n.on('languageChanged', (lng: string) => {
      switchLocale({ variables: { input: { locale: lng } } });
    });
  }, []);

  return (
    <>
      {isMobile.phone ? (
        <>
          <div className='sticky top-0 z-50 flex items-center px-2 py-1 bg-white shadow-sm'>
            {showBack && (
              <LeftIcon
                className='text-gray-500'
                size='1.5rem'
                onClick={() => {
                  if (history.length <= 1) {
                    history.replace('/');
                  } else {
                    history.goBack();
                  }
                }}
              />
            )}
            <div
              className='flex items-center'
              onClick={() => history.replace('/')}
            >
              <img className='w-8 h-8 mx-2' src={imagePath(logoFile)} />
              <span className='ml-2 text-lg font-semibold'>
                {t('dashboard')}
              </span>
            </div>
            <Button
              className='ml-auto text-gray-500'
              type='link'
              size='large'
              onClick={() => setDrawerVisible(true)}
              icon={<MenuOutlined />}
            />
            <div className={mixinEnv && 'w-24'} />
          </div>
          <Drawer
            visible={drawerVisible}
            bodyStyle={{ padding: 0 }}
            closable={false}
            onClose={() => setDrawerVisible(false)}
            placement='right'
          >
            <div className='mt-12'>
              <MenuComponent setDrawerVisible={setDrawerVisible} />
            </div>
          </Drawer>
        </>
      ) : (
        <Layout.Sider
          theme='light'
          style={{ height: '100%', position: 'fixed', overflowY: 'scroll' }}
        >
          <MenuComponent setDrawerVisible={setDrawerVisible} />
        </Layout.Sider>
      )}
    </>
  );
}
