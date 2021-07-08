import { Avatar, Descriptions, Empty, PageHeader, Space, Tabs } from 'antd';
import ArticleSnapshotsComponent from 'apps/admin/components/ArticleSnapshotsComponent/ArticleSnapshotsComponent';
import CommentsComponent from 'apps/admin/components/CommentsComponent/CommentsComponent';
import LoadingComponent from 'apps/admin/components/LoadingComponent/LoadingComponent';
import MixinNetworkSnapshotsComponent from 'apps/admin/components/MixinNetworkSnapshotsComponent/MixinNetworkSnapshotComponent';
import OrdersComponent from 'apps/admin/components/OrdersComponent/OrdersComponent';
import TransfersComponent from 'apps/admin/components/TransfersComponent/TransfersComponent';
import WalletBalanceComponent from 'apps/admin/components/WalletBalanceComponent/WalletBalanceComponent';
import { useAdminArticleQuery } from 'graphqlTypes';
import React from 'react';
import { useHistory, useParams } from 'react-router-dom';

export default function ArticlePage() {
  const { uuid } = useParams<{ uuid: string }>();
  const history = useHistory();
  const { loading, data } = useAdminArticleQuery({
    variables: { uuid },
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const { adminArticle: article } = data;

  return (
    <div>
      <PageHeader title={article.title} onBack={() => history.goBack()} />
      <Descriptions bordered size='small'>
        <Descriptions.Item label='Title'>{article.title}</Descriptions.Item>
        <Descriptions.Item label='Author'>
          <Space>
            <Avatar src={article.author.avatar}>
              {article.author.name[0]}
            </Avatar>
            {article.author.name}
          </Space>
        </Descriptions.Item>
        <Descriptions.Item label='State'>{article.state}</Descriptions.Item>
        <Descriptions.Item label='Price'>{article.price}</Descriptions.Item>
        <Descriptions.Item label='OrdersCount'>
          {article.ordersCount}
        </Descriptions.Item>
        <Descriptions.Item label='Revenue'>
          ${article.revenueUsd}
        </Descriptions.Item>
        <Descriptions.Item label='Comments'>
          {article.commentsCount}
        </Descriptions.Item>
        <Descriptions.Item label='createdAt'>
          {article.createdAt}
        </Descriptions.Item>
      </Descriptions>
      <Tabs defaultActiveKey='orders'>
        <Tabs.TabPane tab='Orders' key='orders'>
          <OrdersComponent itemId={article.id} itemType='Article' />
        </Tabs.TabPane>
        <Tabs.TabPane tab='Comments' key='comments'>
          <CommentsComponent
            commentableId={article.id}
            commentableType='Article'
          />
        </Tabs.TabPane>
        <Tabs.TabPane tab='Snapshots' key='snapshot'>
          <ArticleSnapshotsComponent articleUuid={article.uuid} />
        </Tabs.TabPane>
        <Tabs.TabPane tab='Transfers' key='transfers'>
          <TransfersComponent itemId={article.id} itemType='Article' />
        </Tabs.TabPane>
        <Tabs.TabPane tab='Wallet Balance' key='wallet_balance'>
          {article.walletId ? (
            <WalletBalanceComponent userId={article.walletId} />
          ) : (
            <Empty />
          )}
        </Tabs.TabPane>
        <Tabs.TabPane tab='Wallet Snapshots' key='wallet_snapshots'>
          {article.walletId ? (
            <MixinNetworkSnapshotsComponent userId={article.walletId} />
          ) : (
            <Empty />
          )}
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
