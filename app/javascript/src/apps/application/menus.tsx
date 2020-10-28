import { MenuOutlined } from '@ant-design/icons';
import { Avatar, Button, Col, Drawer, Dropdown, Layout, Menu, Row } from 'antd';
import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useCurrentUser, useMixin } from './shared';

export default function Menus() {
  const currentUser = useCurrentUser();
  const { mixinEnv } = useMixin();
  const [drawerVisible, setDrawerVisible] = useState(false);
  const MenuConent = (props: { mode: 'horizontal' | 'vertical' }) => (
    <Row
      justify='center'
      style={
        props.mode === 'horizontal'
          ? { flexWrap: 'nowrap' }
          : { flexDirection: 'column' }
      }
    >
      <Col>
        <h1 style={{ padding: '0 1rem', textAlign: 'center' }}>LOGO</h1>
      </Col>
      <Col flex={1}>
        <Menu theme='light' mode={props.mode} selectable={false}>
          <Menu.Item onClick={() => setDrawerVisible(false)}>
            <Link to='/' replace>
              读文章
            </Link>
          </Menu.Item>
          <Menu.Item onClick={() => setDrawerVisible(false)}>
            {currentUser ? (
              <Link to='/articles/new' replace>
                写文章
              </Link>
            ) : (
              <a href={`/login?redirect_uri=${location.href}`}>New</a>
            )}
          </Menu.Item>
          <Menu.Item onClick={() => setDrawerVisible(false)}>
            <Link to='/rules' replace>规则</Link>
          </Menu.Item>
        </Menu>
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
                    <a>个人中心</a>
                  </Link>
                </Menu.Item>
                <Menu.Item onClick={() => setDrawerVisible(false)}>
                  <a href='/logout'>登出</a>
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
            Login
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
            placement='left'
          >
            <MenuConent mode='vertical' />
          </Drawer>
          <div style={{ position: 'fixed', bottom: '100px', zIndex: 11 }}>
            <Button
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
