import { Avatar, Descriptions, Empty, PageHeader, Space, Tabs } from 'antd';
import { ArticlesComponent } from 'apps/admin/components/ArticlesComponent/ArticlesComponent';
import CommentsComponent from 'apps/admin/components/CommentsComponent/CommentsComponent';
import LoadingComponent from 'apps/admin/components/LoadingComponent/LoadingComponent';
import MixinNetworkSnapshotsComponent from 'apps/admin/components/MixinNetworkSnapshotsComponent/MixinNetworkSnapshotComponent';
import PaymentsComponent from 'apps/admin/components/PaymentsComponent/PaymentsComponent';
import SwapOrdersComponent from 'apps/admin/components/SwapOrdersComponent/SwapOrdersComponent';
import WalletBalanceComponent from 'apps/admin/components/WalletBalanceComponent/WalletBalanceComponent';
import { useAdminUserQuery } from 'graphqlTypes';
import React from 'react';
import { useParams } from 'react-router-dom';

export default function UserPage() {
  const { mixinId } = useParams<{ mixinId: string }>();
  const { loading, data } = useAdminUserQuery({ variables: { mixinId } });

  if (loading) {
    return <LoadingComponent />;
  }

  const { adminUser: user } = data;
  return (
    <div>
      <PageHeader title='Users' />
      <Descriptions bordered size='small'>
        <Descriptions.Item label='Name'>
          <Space>
            <Avatar src={user.avatar} />
            {user.name}
          </Space>
        </Descriptions.Item>
        <Descriptions.Item label='MixinId'>{user.mixinId}</Descriptions.Item>
        <Descriptions.Item label='Articles Count'>
          {user.statistics.articlesCount}
        </Descriptions.Item>
        <Descriptions.Item label='Author Revenue Amount(USD)'>
          {user.statistics.authorRevenueTotalUsd}
        </Descriptions.Item>
        <Descriptions.Item label='Reader Revenue Amount(USD)'>
          {user.statistics.readerRevenueTotalUsd}
        </Descriptions.Item>
      </Descriptions>
      <Tabs defaultActiveKey='articles'>
        <Tabs.TabPane tab='Articles' key='articles'>
          <ArticlesComponent authorMixinUuid={user.mixinUuid} />
        </Tabs.TabPane>
        <Tabs.TabPane tab='Comments' key='comments'>
          <CommentsComponent authorMixinUuid={user.mixinUuid} />
        </Tabs.TabPane>
        <Tabs.TabPane tab='Payments' key='payments'>
          <PaymentsComponent payerMixinUuid={user.mixinUuid} />
        </Tabs.TabPane>
        <Tabs.TabPane tab='Swap Orders' key='swap_orders'>
          <SwapOrdersComponent payerMixinUuid={user.mixinUuid} />
        </Tabs.TabPane>
        <Tabs.TabPane tab='Wallet Balance' key='wallet_balance'>
          {user.walletId ? (
            <WalletBalanceComponent userId={user.walletId} />
          ) : (
            <Empty />
          )}
        </Tabs.TabPane>
        <Tabs.TabPane tab='Wallet Snapshots' key='wallet_snapshots'>
          {user.walletId ? (
            <MixinNetworkSnapshotsComponent userId={user.walletId} />
          ) : (
            <Empty />
          )}
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
