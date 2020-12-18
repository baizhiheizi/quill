import { MenuOutlined } from '@ant-design/icons';
import { imagePath, useUserAgent } from '@shared';
import { Avatar, Button, Drawer, Layout, Menu } from 'antd';
import React, { useState } from 'react';
import { Link } from 'react-router-dom';

export default function Menus() {
  const { isMobile } = useUserAgent();
  const [drawerVisible, setDrawerVisible] = useState(false);
  const MenuConent = () => (
    <div>
      <div style={{ margin: 15, textAlign: 'center' }}>
        <Link to='/' replace>
          <Avatar size='large' src={imagePath('logo.svg')} />
        </Link>
      </div>
      <Menu mode='inline'>
        <Menu.Item>
          <Link to='/'>Overview</Link>
        </Menu.Item>
        <Menu.Item>
          <Link to='/'>Article Manage</Link>
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
        <Layout.Sider theme='light' style={{ height: '100%' }}>
          <MenuConent />
        </Layout.Sider>
      )}
    </div>
  );
}
