import CommentsComponent from '@admin/components/CommentsComponent/CommentsComponent';
import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import OrdersComponent from '@admin/components/OrdersComponent/OrdersComponent';
import { useAdminArticleQuery } from '@graphql';
import { Avatar, Descriptions, PageHeader, Space, Tabs } from 'antd';
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
            <Avatar src={article.author.avatarUrl}>
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
        <Descriptions.Item label='Revenue'>{article.revenue}</Descriptions.Item>
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
        <Tabs.TabPane tab='Transfers' key='transfers'>
          Transfers
        </Tabs.TabPane>
        <Tabs.TabPane tab='Wallet Balance' key='wallet_balance'>
          Wallet Balance
        </Tabs.TabPane>
        <Tabs.TabPane tab='Wallet Snapshots' key='wallet_snapshots'>
          Wallet Snapshots
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
