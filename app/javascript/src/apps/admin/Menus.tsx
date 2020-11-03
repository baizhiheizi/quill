import { Menu } from 'antd';
import React from 'react';

export default function Menus() {
  return (
    <Menu theme='dark'>
      <div
        style={{
          height: '2rem',
          margin: '1rem',
          lineHeight: '2rem',
          textAlign: 'center',
        }}
      >
        Admin
      </div>
      <Menu.Item>Dashboard</Menu.Item>
      <Menu.Item>Users</Menu.Item>
      <Menu.Item>Articles</Menu.Item>
      <Menu.Item>Comments</Menu.Item>
      <Menu.Item>Payments</Menu.Item>
      <Menu.Item>Transfers</Menu.Item>
    </Menu>
  );
}
