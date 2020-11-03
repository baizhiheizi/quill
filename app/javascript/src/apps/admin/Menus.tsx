import { Menu } from 'antd';
import React from 'react';
import { Link } from 'react-router-dom';

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
      <Menu.Item>
        <Link to='/'>Dashboard</Link>
      </Menu.Item>
      <Menu.Item>
        <Link to='/users'>Users</Link>
      </Menu.Item>
      <Menu.Item>
        <Link to='/articles'>Articles</Link>
      </Menu.Item>
      <Menu.Item>
        <Link to='/comments'>Comments</Link>
      </Menu.Item>
      <Menu.Item>
        <Link to='/payments'>Payments</Link>
      </Menu.Item>
      <Menu.Item>
        <Link to='/transfers'>Transfers</Link>
      </Menu.Item>
      <Menu.Item>
        <a href='/admin/logout'>Logout</a>
      </Menu.Item>
    </Menu>
  );
}
