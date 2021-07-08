import { Avatar, Button, Select, Space, Table } from 'antd';
import { ColumnProps } from 'antd/es/table';
import LoadingComponent from 'apps/admin/components/LoadingComponent/LoadingComponent';
import { Order, useAdminOrderConnectionQuery } from 'graphqlTypes';
import React, { useState } from 'react';
import { useHistory } from 'react-router-dom';

export default function OrdersComponent(props: {
  itemId?: string;
  itemType?: string;
}) {
  const [state, setState] = useState('all');
  const { itemId, itemType } = props;
  const { loading, data, fetchMore, refetch } = useAdminOrderConnectionQuery({
    variables: { state, itemId, itemType },
  });
  const history = useHistory();

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
      dataIndex: 'item',
      key: 'item',
      render: (_, order) =>
        order.itemType === 'Article' && (
          <a
            className='w-full cursor-pointer line-clamp-1'
            onClick={() => history.push(`/articles/${order.item.uuid}`)}
          >
            {order.item.title}
          </a>
        ),
      title: 'Item',
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
          <Avatar src={order.buyer.avatar} />
          {order.buyer.name}
        </Space>
      ),
      title: 'Buyer',
    },
    {
      dataIndex: 'total',
      key: 'total',
      render: (_, order) => (
        <span>
          {order.total} {order.currency.symbol}
        </span>
      ),
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
    <>
      <div className='flex justify-between mb-4'>
        <div className='flex space-x-4'>
          <Select
            className='w-48'
            value={state}
            onChange={(value) => setState(value)}
          >
            <Select.Option value='all'>All</Select.Option>
            <Select.Option value='paid'>Paid</Select.Option>
            <Select.Option value='completed'>Completed</Select.Option>
          </Select>
        </div>
        <Button type='primary' onClick={() => refetch()}>
          Refresh
        </Button>
      </div>
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={orders}
        rowKey='traceId'
        pagination={false}
        size='small'
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
    </>
  );
}
