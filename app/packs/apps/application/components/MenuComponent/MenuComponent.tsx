import {
  GithubOutlined,
  GlobalOutlined,
  NotificationOutlined,
} from '@ant-design/icons';
import { Avatar, Badge, Button, Col, Menu, Row } from 'antd';
import { OPEN_SOURCE_URL } from 'apps/application/shared';
import { imagePath, useCurrentUser, usePrsdigg } from 'apps/shared';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';

export default function MenuComponent(props: {
  mode: 'horizontal' | 'vertical';
  setDrawerVisible?: (visible: boolean) => void;
}) {
  const { currentUser } = useCurrentUser();
  const { logoFile } = usePrsdigg();
  const { mode, setDrawerVisible } = props;
  const { t, i18n } = useTranslation();

  return (
    <Row
      justify='center'
      style={
        mode === 'horizontal'
          ? { flexWrap: 'nowrap' }
          : { flexDirection: 'column', textAlign: 'center' }
      }
    >
      <Col>
        {currentUser && mode === 'vertical' ? (
          <div style={{ margin: 15 }}>
            <a href='/dashboard'>
              <Avatar size='large' src={currentUser.avatar}>
                {currentUser.name[0]}
              </Avatar>
            </a>
          </div>
        ) : (
          <div style={{ margin: '0 15px' }}>
            <Link to='/' replace>
              <Avatar size='large' src={imagePath(logoFile)} />
            </Link>
          </div>
        )}
      </Col>
      <Col flex={1}>
        <Menu theme='light' mode={mode} selectable={false}>
          <Menu.Item key='read' onClick={() => setDrawerVisible(false)}>
            <Link to='/' replace>
              {t('read')}
            </Link>
          </Menu.Item>
          <Menu.Item key='write' onClick={() => setDrawerVisible(false)}>
            {currentUser ? (
              <a href='/dashboard/articles/new' target='_blank'>
                {t('write')}
              </a>
            ) : (
              <a href={`/login?return_to=${encodeURIComponent(location.href)}`}>
                {t('write')}
              </a>
            )}
          </Menu.Item>
          <Menu.Item key='search' onClick={() => setDrawerVisible(false)}>
            <Link to='/search' replace>
              {t('search')}
            </Link>
          </Menu.Item>
          <Menu.Item key='rules' onClick={() => setDrawerVisible(false)}>
            <Link to='/rules' replace>
              {t('rules')}
            </Link>
          </Menu.Item>
          <Menu.Item key='fair' onClick={() => setDrawerVisible(false)}>
            <Link to='/fair' replace>
              {t('fair')}
            </Link>
          </Menu.Item>
          <Menu.Item key='open_source' onClick={() => setDrawerVisible(false)}>
            <a href={OPEN_SOURCE_URL} target='_blank'>
              <GithubOutlined className='mr-2' />
              {t('open_source')}
            </a>
          </Menu.Item>
        </Menu>
      </Col>
      {i18n.languages.length > 1 && (
        <Col>
          <Menu theme='light' mode={mode} selectable={false}>
            <Menu.SubMenu
              key='global'
              title={
                mode === 'horizontal' ? (
                  <GlobalOutlined />
                ) : i18n.language.includes('en') ? (
                  'Language'
                ) : i18n.language.includes('ja') ? (
                  '言語'
                ) : (
                  '语言'
                )
              }
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
          </Menu>
        </Col>
      )}
      {currentUser ? (
        <Col>
          <Menu mode={mode} selectable={false}>
            <Menu.Item
              key='notifications'
              onClick={() => setDrawerVisible(false)}
            >
              <Badge dot={currentUser.unreadNotificationsCount > 0}>
                <a href='/dashboard/notifications'>
                  {mode === 'horizontal' ? (
                    <NotificationOutlined />
                  ) : (
                    t('notifications_manage')
                  )}
                </a>
              </Badge>
            </Menu.Item>
            <Menu.Item key='dashboard' onClick={() => setDrawerVisible(false)}>
              <a href='/dashboard' target='_blank'>
                {t('dashboard')}
              </a>
            </Menu.Item>
            <Menu.Item key='logout' onClick={() => setDrawerVisible(false)}>
              <a href='/logout'>{t('logout')}</a>
            </Menu.Item>
          </Menu>
        </Col>
      ) : (
        <Col>
          <Button type='link' href='/login'>
            {t('login')}
          </Button>
        </Col>
      )}
    </Row>
  );
}
