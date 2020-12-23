import { GithubOutlined, MenuOutlined } from '@ant-design/icons';
import { imagePath, useCurrentUser, useUserAgent } from '@shared';
import { Avatar, Button, Col, Drawer, Layout, Menu, Row } from 'antd';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { OPEN_SOURCE_URL } from './shared';

export default function Menus() {
  const currentUser = useCurrentUser();
  const { isMobile } = useUserAgent();
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
            {currentUser ? (
              <Avatar src={currentUser.avatarUrl}>{currentUser.name[0]}</Avatar>
            ) : (
              <Avatar size='large' src={imagePath('logo.svg')} />
            )}
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
              <a href='/dashboard/articles/new' target='_blank'>
                {t('menu.write')}
              </a>
            ) : (
              <a href={`/login?return_to=${encodeURIComponent(location.href)}`}>
                {t('menu.write')}
              </a>
            )}
          </Menu.Item>
          <Menu.Item onClick={() => setDrawerVisible(false)}>
            <Link to='/search' replace>
              {t('menu.search')}
            </Link>
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
            <Link to='/community' replace>
              {t('menu.community')}
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
        <Menu theme='light' mode={props.mode} selectable={false}>
          <Menu.SubMenu title={i18n.language.includes('en') ? 'EN' : '中文'}>
            <Menu.Item>
              <a onClick={() => i18n.changeLanguage('zh-CN')}>中文</a>
            </Menu.Item>
            <Menu.Item>
              <a onClick={() => i18n.changeLanguage('en-US')}>EN</a>
            </Menu.Item>
          </Menu.SubMenu>
        </Menu>
      </Col>
      {currentUser ? (
        <Col>
          <Menu mode={props.mode} selectable={false}>
            <Menu.Item onClick={() => setDrawerVisible(false)}>
              <a href='/dashboard' target='_blank'>
                {t('menu.mine')}
              </a>
            </Menu.Item>
            <Menu.Item onClick={() => setDrawerVisible(false)}>
              <a href='/logout'>{t('menu.logout')}</a>
            </Menu.Item>
          </Menu>
        </Col>
      ) : (
        <Col>
          <Button type='link' href='/login'>
            {t('menu.login')}
          </Button>
        </Col>
      )}
    </Row>
  );
  return (
    <React.Fragment>
      {isMobile.phone ? (
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
