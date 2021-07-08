import {
  CommentOutlined,
  DashboardOutlined,
  FileTextOutlined,
  LineChartOutlined,
  LinkOutlined,
  LogoutOutlined,
  MessageOutlined,
  MoneyCollectOutlined,
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
    <Menu theme='dark' mode='inline'>
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
      <Menu.Item key='dashboard'>
        <Link to='/'>
          <DashboardOutlined />
          <span>Dashboard</span>
        </Link>
      </Menu.Item>
      <Menu.SubMenu
        key='statistic'
        icon={<LineChartOutlined />}
        title='Statistic'
      >
        <Menu.Item key='daily_statistic'>
          <Link to='/daily_statistic'>
            <span>Daily</span>
          </Link>
        </Menu.Item>
      </Menu.SubMenu>
      <Menu.Item key='users'>
        <Link to='/users'>
          <UserOutlined />
          <span>Users</span>
        </Link>
      </Menu.Item>
      <Menu.SubMenu key='article' icon={<FileTextOutlined />} title='Article'>
        <Menu.Item key='articles'>
          <Link to='/articles'>
            <span>Articles</span>
          </Link>
        </Menu.Item>
        <Menu.Item key='article_snapshots'>
          <Link to='/article_snapshots'>
            <span>Article Snapshots</span>
          </Link>
        </Menu.Item>
      </Menu.SubMenu>
      <Menu.SubMenu key='pressone' icon={<LinkOutlined />} title='PRESSOne'>
        <Menu.Item key='prs_accounts'>
          <Link to='/prs_accounts'>
            <span>Accounts</span>
          </Link>
        </Menu.Item>
        <Menu.Item key='prs_transactions'>
          <Link to='/prs_transactions'>
            <span>Transactions</span>
          </Link>
        </Menu.Item>
      </Menu.SubMenu>
      <Menu.Item key='comments'>
        <Link to='/comments'>
          <CommentOutlined />
          <span>Comments</span>
        </Link>
      </Menu.Item>
      <Menu.Item key='payments'>
        <Link to='/payments'>
          <PayCircleOutlined />
          <span>Payments</span>
        </Link>
      </Menu.Item>
      <Menu.Item key='orders'>
        <Link to='/orders'>
          <MoneyCollectOutlined />
          <span>Orders</span>
        </Link>
      </Menu.Item>
      <Menu.Item key='swap_orders'>
        <Link to='/swap_orders'>
          <SwapOutlined />
          <span>Swap Orders</span>
        </Link>
      </Menu.Item>
      <Menu.Item key='transfers'>
        <Link to='/transfers'>
          <TransactionOutlined />
          <span>Transfers</span>
        </Link>
      </Menu.Item>
      <Menu.Item key='announcements'>
        <Link to='/announcements'>
          <NotificationOutlined />
          <span>Announcements</span>
        </Link>
      </Menu.Item>
      <Menu.Item key='mixin_messages'>
        <Link to='/mixin_messages'>
          <MessageOutlined />
          <span>Messages</span>
        </Link>
      </Menu.Item>
      <Menu.Item key='mixin_network_snapshots'>
        <Link to='/mixin_network_snapshots'>
          <TableOutlined />
          <span>Snapshots</span>
        </Link>
      </Menu.Item>
      <Menu.Item key='bonuses'>
        <Link to='/bonuses'>
          <TrophyOutlined />
          <span>Bonuses</span>
        </Link>
      </Menu.Item>
      <Menu.Item key='balance'>
        <Link to='/balance'>
          <WalletOutlined />
          <span>Balance</span>
        </Link>
      </Menu.Item>
      <Menu.Item key='logout'>
        <a href='/admin/logout'>
          <LogoutOutlined />
          <span>Logout</span>
        </a>
      </Menu.Item>
    </Menu>
  );
}
