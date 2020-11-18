import { imagePath } from '@/shared';
import { GithubOutlined, MenuOutlined } from '@ant-design/icons';
import {
  Avatar,
  Button,
  Col,
  Divider,
  Drawer,
  Dropdown,
  Layout,
  Menu,
  Row,
} from 'antd';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { OPEN_SOURCE_URL, useCurrentUser, useUserAgent } from './shared';

export default function Menus() {
  const currentUser = useCurrentUser();
  const { mixinEnv } = useUserAgent();
  const [drawerVisible, setDrawerVisible] = useState(false);
  const { t, i18n } = useTranslation();
  const MenuConent = (props: { mode: 'horizontal' | 'vertical' }) => (
    <Row
      justify='center'
      style={
        props.mode === 'horizontal'
          ? { flexWrap: 'nowrap' }
          : { flexDirection: 'column', textAlign: 'center' }
      }
    >
      <Col>
        <div style={{ margin: '0 15px' }}>
          <Link to='/' replace>
            <Avatar size='large' src={imagePath('logo.svg')} />
          </Link>
        </div>
      </Col>
      <Col flex={1}>
        <Menu theme='light' mode={props.mode} selectable={false}>
          <Menu.Item onClick={() => setDrawerVisible(false)}>
            <Link to='/' replace>
              {t('menu.read')}
            </Link>
          </Menu.Item>
          <Menu.Item onClick={() => setDrawerVisible(false)}>
            {currentUser ? (
              <Link to='/articles/new' replace>
                {t('menu.write')}
              </Link>
            ) : (
              <a href={`/login?redirect_uri=${location.href}`}>
                {t('menu.write')}
              </a>
            )}
          </Menu.Item>
          <Menu.Item onClick={() => setDrawerVisible(false)}>
            <Link to='/rules' replace>
              {t('menu.rules')}
            </Link>
          </Menu.Item>
          <Menu.Item onClick={() => setDrawerVisible(false)}>
            <Link to='/fair' replace>
              {t('menu.fair')}
            </Link>
          </Menu.Item>
          <Menu.Item onClick={() => setDrawerVisible(false)}>
            <a href={OPEN_SOURCE_URL} target='_blank'>
              <GithubOutlined />
              {t('menu.openSource')}
            </a>
          </Menu.Item>
        </Menu>
      </Col>
      <Col>
        <div
          style={
            props.mode === 'horizontal'
              ? { display: 'inline-block' }
              : { marginBottom: '1rem' }
          }
        >
          {i18n.language.includes('en') ? (
            <a onClick={() => i18n.changeLanguage('zh-CN')}>中文</a>
          ) : (
            '中文'
          )}
          <Divider type='vertical' />
          {i18n.language.includes('zh') ? (
            <a onClick={() => i18n.changeLanguage('en-US')}>EN</a>
          ) : (
            'EN'
          )}
        </div>
      </Col>
      <Col>
        {currentUser ? (
          <Dropdown
            placement='bottomLeft'
            trigger={['click']}
            overlay={
              <Menu selectable={false}>
                <Menu.Item onClick={() => setDrawerVisible(false)}>
                  <Link to='/mine' replace>
                    <a>{t('menu.mine')}</a>
                  </Link>
                </Menu.Item>
                <Menu.Item onClick={() => setDrawerVisible(false)}>
                  <a href='/logout'>{t('menu.logout')}</a>
                </Menu.Item>
              </Menu>
            }
          >
            <div style={{ padding: '0 1rem' }}>
              <Avatar src={currentUser.avatarUrl}>{currentUser.name[0]}</Avatar>
            </div>
          </Dropdown>
        ) : (
          <Button type='link' href='/login'>
            {t('menu.login')}
          </Button>
        )}
      </Col>
    </Row>
  );
  return (
    <React.Fragment>
      {mixinEnv ? (
        <div>
          <Drawer
            bodyStyle={{ padding: 0 }}
            visible={drawerVisible}
            closable={false}
            onClose={() => setDrawerVisible(false)}
            placement='right'
          >
            <MenuConent mode='vertical' />
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
        <Layout.Header
          style={{
            WebkitBoxShadow: '0 2px 8px #f0f1f2',
            background: '#fff',
            boxShadow: '0 2px 8px #f0f1f2',
            padding: 0,
            zIndex: 10,
          }}
        >
          <MenuConent mode='horizontal' />
        </Layout.Header>
      )}
    </React.Fragment>
  );
}
