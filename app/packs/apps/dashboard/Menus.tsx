import {
  AccountBookOutlined,
  BookOutlined,
  CommentOutlined,
  DashboardOutlined,
  FileTextOutlined,
  GlobalOutlined,
  LoginOutlined,
  MenuOutlined,
  NotificationOutlined,
  RiseOutlined,
  SettingOutlined,
} from '@ant-design/icons';
import { useSwitchLocaleMutation } from '@graphql';
import { imagePath, useCurrentUser, useUserAgent } from '@shared';
import { Avatar, Badge, Button, Drawer, Layout, Menu } from 'antd';
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';

export default function Menus() {
  const { isMobile } = useUserAgent();
  const { t, i18n } = useTranslation();
  const [drawerVisible, setDrawerVisible] = useState(false);
  const { currentUser } = useCurrentUser();
  const [switchLocale] = useSwitchLocaleMutation();

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

  const MenuConent = () => (
    <div>
      <div style={{ margin: 15, textAlign: 'center' }}>
        <a href='/'>
          <Avatar size='large' src={imagePath('logo.svg')} />
        </a>
      </div>
      <Menu mode='inline' defaultSelectedKeys={[defaultKey]}>
        <Menu.Item key='overview' onClick={() => setDrawerVisible(false)}>
          <Link to='/'>
            <DashboardOutlined />
            <span>{t('dashboard.menu.overview')}</span>
          </Link>
        </Menu.Item>
        <Menu.Item key='notifications' onClick={() => setDrawerVisible(false)}>
          <Badge dot={currentUser?.unreadNotificationsCount > 0}>
            <Link to='/notifications'>
              <NotificationOutlined />
              <span>{t('dashboard.menu.notifications')}</span>
            </Link>
          </Badge>
        </Menu.Item>
        <Menu.Item key='settings' onClick={() => setDrawerVisible(false)}>
          <Link to='/settings'>
            <SettingOutlined />
            <span>{t('dashboard.menu.settings')}</span>
          </Link>
        </Menu.Item>
        <Menu.Item key='articles' onClick={() => setDrawerVisible(false)}>
          <Link to='/articles'>
            <FileTextOutlined />
            <span>{t('dashboard.menu.articles')}</span>
          </Link>
        </Menu.Item>
        <Menu.Item key='subscriptions' onClick={() => setDrawerVisible(false)}>
          <Link to='/subscriptions'>
            <BookOutlined />
            <span>{t('dashboard.menu.subscriptions')}</span>
          </Link>
        </Menu.Item>
        <Menu.Item key='revenue' onClick={() => setDrawerVisible(false)}>
          <Link to='/revenue'>
            <RiseOutlined />
            <span>{t('dashboard.menu.revenue')}</span>
          </Link>
        </Menu.Item>
        <Menu.Item key='orders' onClick={() => setDrawerVisible(false)}>
          <Link to='/orders'>
            <AccountBookOutlined />
            <span>{t('dashboard.menu.orders')}</span>
          </Link>
        </Menu.Item>
        <Menu.Item key='comments' onClick={() => setDrawerVisible(false)}>
          <Link to='/comments'>
            <CommentOutlined />
            <span>{t('dashboard.menu.comments')}</span>
          </Link>
        </Menu.Item>
        <Menu.SubMenu
          title={i18n.language.includes('en') ? 'Language' : '语言'}
          icon={<GlobalOutlined />}
        >
          <Menu.Item>
            <a onClick={() => i18n.changeLanguage('zh-CN')}>中文</a>
          </Menu.Item>
          <Menu.Item>
            <a onClick={() => i18n.changeLanguage('en')}>EN</a>
          </Menu.Item>
        </Menu.SubMenu>
        <Menu.Item key='back'>
          <a href='/'>
            <LoginOutlined />
            <span>{t('dashboard.menu.back')}</span>
          </a>
        </Menu.Item>
      </Menu>
    </div>
  );
  return (
    <div>
      {isMobile.phone ? (
        <div>
          <Drawer
            visible={drawerVisible}
            bodyStyle={{ padding: 0 }}
            closable={false}
            onClose={() => setDrawerVisible(false)}
            placement='right'
          >
            <MenuConent />
          </Drawer>
          <div
            style={{
              position: 'fixed',
              right: '0px',
              bottom: '100px',
              zIndex: 11,
            }}
          >
            <Button
              type='primary'
              size='large'
              onClick={() => setDrawerVisible(true)}
              icon={<MenuOutlined />}
            />
          </div>
        </div>
      ) : (
        <Layout.Sider
          theme='light'
          style={{ height: '100%', position: 'fixed', overflowY: 'scroll' }}
        >
          <MenuConent />
        </Layout.Sider>
      )}
    </div>
  );
}
