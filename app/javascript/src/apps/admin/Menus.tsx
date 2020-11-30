import {
  CommentOutlined,
  DashboardOutlined,
  FileTextOutlined,
  LogoutOutlined,
  MessageOutlined,
  NotificationOutlined,
  PayCircleOutlined,
  SwapOutlined,
  TableOutlined,
  TransactionOutlined,
  TrophyOutlined,
  UserOutlined,
  WalletOutlined,
} from '@ant-design/icons';
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
        <Link to='/'>
          <DashboardOutlined />
          <span>Dashboard</span>
        </Link>
      </Menu.Item>
      <Menu.Item>
        <Link to='/users'>
          <UserOutlined />
          <span>Users</span>
        </Link>
      </Menu.Item>
      <Menu.Item>
        <Link to='/articles'>
          <FileTextOutlined />
          <span>Articles</span>
        </Link>
      </Menu.Item>
      <Menu.Item>
        <Link to='/comments'>
          <CommentOutlined />
          <span>Comments</span>
        </Link>
      </Menu.Item>
      <Menu.Item>
        <Link to='/payments'>
          <PayCircleOutlined />
          <span>Payments</span>
        </Link>
      </Menu.Item>
      <Menu.Item>
        <Link to='/swap_orders'>
          <SwapOutlined />
          <span>Swap Orders</span>
        </Link>
      </Menu.Item>
      <Menu.Item>
        <Link to='/transfers'>
          <TransactionOutlined />
          <span>Transfers</span>
        </Link>
      </Menu.Item>
      <Menu.Item>
        <Link to='/announcements'>
          <NotificationOutlined />
          <span>Announcements</span>
        </Link>
      </Menu.Item>
      <Menu.Item>
        <Link to='/mixin_messages'>
          <MessageOutlined />
          <span>Messages</span>
        </Link>
      </Menu.Item>
      <Menu.Item>
        <Link to='/mixin_network_snapshots'>
          <TableOutlined />
          <span>Snapshots</span>
        </Link>
      </Menu.Item>
      <Menu.Item>
        <Link to='/bonuses'>
          <TrophyOutlined />
          <span>Bonuses</span>
        </Link>
      </Menu.Item>
      <Menu.Item>
        <Link to='/balance'>
          <WalletOutlined />
          <span>Balance</span>
        </Link>
      </Menu.Item>
      <Menu.Item>
        <a href='/admin/logout'>
          <LogoutOutlined />
          <span>Logout</span>
        </a>
      </Menu.Item>
    </Menu>
  );
}
