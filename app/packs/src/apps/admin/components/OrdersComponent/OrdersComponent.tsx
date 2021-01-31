import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import { Order, useAdminOrderConnectionQuery } from '@graphql';
import { Avatar, Button, Space, Table } from 'antd';
import { ColumnProps } from 'antd/es/table';
import React from 'react';

export default function OrdersComponent(props: {
  itemId?: string;
  itemType?: string;
}) {
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
