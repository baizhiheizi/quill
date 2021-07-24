import { MenuOutlined } from '@ant-design/icons';
import { Left as LeftIcon } from '@icon-park/react';
import { Button, Drawer, Layout } from 'antd';
import {
  imagePath,
  useCurrentUser,
  usePrsdigg,
  useUserAgent,
} from 'apps/shared';
import { useSwitchLocaleMutation } from 'graphqlTypes';
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useHistory, useLocation } from 'react-router-dom';
import MenuComponent from '../MenuComponent/MenuComponent';

export default function HeaderComponent() {
  const location = useLocation();
  const { currentUser } = useCurrentUser();
  const { i18n } = useTranslation();
  const [switchLocale] = useSwitchLocaleMutation();
  const history = useHistory();
  const { appName, logoFile } = usePrsdigg();
  const { mixinEnv } = useUserAgent();
  const [drawerVisible, setDrawerVisible] = useState(false);
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
      <div className='sticky top-0 z-50 flex items-center px-2 py-1 bg-white md:hidden shadow-sm'>
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
        <div className='flex items-center' onClick={() => history.replace('/')}>
          <img className='w-8 h-8 mx-2' src={imagePath(logoFile)} />
          <span className='text-lg font-semibold'>{appName}</span>
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
        bodyStyle={{ padding: 0 }}
        visible={drawerVisible}
        closable={false}
        onClose={() => setDrawerVisible(false)}
        placement='right'
      >
        <div className='mt-12'>
          <MenuComponent mode='vertical' setDrawerVisible={setDrawerVisible} />
        </div>
      </Drawer>
      <Layout.Header
        className='hidden md:block'
        style={{
          WebkitBoxShadow: '0 2px 8px #f0f1f2',
          background: '#fff',
          boxShadow: '0 2px 8px #f0f1f2',
          padding: 0,
          zIndex: 10,
        }}
      >
        <MenuComponent mode='horizontal' />
      </Layout.Header>
    </>
  );
}
