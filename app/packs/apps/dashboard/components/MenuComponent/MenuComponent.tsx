import {
  AccountBookOutlined,
  BookOutlined,
  DashboardOutlined,
  FileTextOutlined,
  GlobalOutlined,
  LoginOutlined,
  NotificationOutlined,
  RiseOutlined,
  SettingOutlined,
} from '@ant-design/icons';
import { Badge, Menu } from 'antd';
import { imagePath, useCurrentUser, usePrsdigg } from 'apps/shared';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';

export default function MenuComponent(props: {
  setDrawerVisible?: (visible: boolean) => void;
}) {
  const { setDrawerVisible } = props;
  const { logoFile } = usePrsdigg();
  const { t, i18n } = useTranslation();
  const { currentUser } = useCurrentUser();

  const keys = [
    'overview',
    'notifications',
    'settings',
    'articles',
    'subscriptions',
    'revenue',
    'orders',
    'comments',
  ];
  let defaultKey = 'overview';
  keys.forEach((key) => {
    if (location.pathname.match(key)) {
      defaultKey = key;
    }
  });

  return (
    <>
      <a className='flex items-center justify-center block my-4' href='/'>
        <img className='w-10 h-10' src={imagePath(logoFile)} />
      </a>
      <Menu mode='inline' defaultSelectedKeys={[defaultKey]}>
        <Menu.Item key='overview' onClick={() => setDrawerVisible(false)}>
          <Link to='/'>
            <DashboardOutlined />
            <span>{t('overview')}</span>
          </Link>
        </Menu.Item>
        <Menu.Item key='notifications' onClick={() => setDrawerVisible(false)}>
          <Badge dot={currentUser?.unreadNotificationsCount > 0}>
            <Link to='/notifications'>
              <NotificationOutlined />
              <span>{t('notifications_manage')}</span>
            </Link>
          </Badge>
        </Menu.Item>
        <Menu.Item key='settings' onClick={() => setDrawerVisible(false)}>
          <Link to='/settings'>
            <SettingOutlined />
            <span>{t('settings')}</span>
          </Link>
        </Menu.Item>
        <Menu.Item key='articles' onClick={() => setDrawerVisible(false)}>
          <Link to='/articles'>
            <FileTextOutlined />
            <span>{t('articles_manage')}</span>
          </Link>
        </Menu.Item>
        <Menu.Item key='subscriptions' onClick={() => setDrawerVisible(false)}>
          <Link to='/subscriptions'>
            <BookOutlined />
            <span>{t('subscriptions_manage')}</span>
          </Link>
        </Menu.Item>
        <Menu.Item key='revenue' onClick={() => setDrawerVisible(false)}>
          <Link to='/revenue'>
            <RiseOutlined />
            <span>{t('revenue_manage')}</span>
          </Link>
        </Menu.Item>
        <Menu.Item key='orders' onClick={() => setDrawerVisible(false)}>
          <Link to='/orders'>
            <AccountBookOutlined />
            <span>{t('orders_manage')}</span>
          </Link>
        </Menu.Item>
        {i18n.languages.length > 1 && (
          <Menu.SubMenu
            key='global'
            title={
              i18n.language.includes('en')
                ? 'Language'
                : i18n.language.includes('ja')
                ? '言語'
                : '语言'
            }
            icon={<GlobalOutlined />}
          >
            {i18n.languages.map((lng) => {
              if (lng.includes('CN')) {
                return (
                  <Menu.Item key={lng}>
                    <a onClick={() => i18n.changeLanguage('zh-CN')}>中文</a>
                  </Menu.Item>
                );
              } else if (lng.includes('en')) {
                return (
                  <Menu.Item key={lng}>
                    <a onClick={() => i18n.changeLanguage('en')}>EN</a>
                  </Menu.Item>
                );
              } else if (lng.includes('ja')) {
                return (
                  <Menu.Item key={lng}>
                    <a onClick={() => i18n.changeLanguage('ja')}>日本語</a>
                  </Menu.Item>
                );
              }
            })}
          </Menu.SubMenu>
        )}
        <Menu.Item key='back'>
          <a href='/'>
            <LoginOutlined />
            <span>{t('back')}</span>
          </a>
        </Menu.Item>
      </Menu>
    </>
  );
}
