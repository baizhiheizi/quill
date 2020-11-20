import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import {
  Order,
  useAdminArticleQuery,
  useAdminOrderConnectionQuery,
} from '@graphql';
import {
  Avatar,
  Button,
  Descriptions,
  PageHeader,
  Space,
  Table,
  Tabs,
} from 'antd';
import { ColumnProps } from 'antd/es/table';
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
          Comments
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

function OrdersComponent(props: { itemId?: string; itemType?: string }) {
  const { itemId, itemType } = props;
  const { loading, data, fetchMore } = useAdminOrderConnectionQuery({
    variables: { itemId, itemType },
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    adminOrderConnection: {
      nodes: orders,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;
  const columns: Array<ColumnProps<Order>> = [
    {
      dataIndex: 'traceId',
      key: 'traceId',
      title: 'traceId',
    },
    {
      dataIndex: 'orderType',
      key: 'orderType',
      title: 'orderType',
    },
    {
      dataIndex: 'buyer',
      key: 'buyer',
      render: (_, order) => (
        <Space>
          <Avatar src={order.buyer.avatarUrl} />
          {order.buyer.name}
        </Space>
      ),
      title: 'Buyer',
    },
    {
      dataIndex: 'total',
      key: 'total',
      title: 'Total',
    },
    {
      dataIndex: 'state',
      key: 'state',
      title: 'state',
    },
    {
      dataIndex: 'createdAt',
      key: 'createdAt',
      title: 'CreatedAt',
    },
  ];

  return (
    <div>
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={orders}
        rowKey='traceId'
        pagination={false}
      />
      <div style={{ margin: '1rem', textAlign: 'center' }}>
        <Button
          type='link'
          loading={loading}
          disabled={!hasNextPage}
          onClick={() => {
            fetchMore({
              updateQuery: (prev, { fetchMoreResult }) => {
                if (!fetchMoreResult) {
                  return prev;
                }
                const connection = fetchMoreResult.adminOrderConnection;
                connection.nodes = prev.adminOrderConnection.nodes.concat(
                  connection.nodes,
                );
                return Object.assign({}, prev, {
                  adminOrderConnection: connection,
                });
              },
              variables: {
                after: endCursor,
              },
            });
          }}
        >
          {hasNextPage ? 'Load More' : 'No More'}
        </Button>
      </div>
    </div>
  );
}
