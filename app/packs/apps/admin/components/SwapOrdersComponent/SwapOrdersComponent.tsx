import { Avatar, Button, Select, Space, Table } from 'antd';
import { ColumnProps } from 'antd/es/table';
import LoadingComponent from 'apps/admin/components/LoadingComponent/LoadingComponent';
import { SwapOrder, useAdminSwapOrderConnectionQuery } from 'graphqlTypes';
import React, { useState } from 'react';

export default function SwapOrdersComponent(props: {
  payerMixinUuid?: string;
}) {
  const { payerMixinUuid } = props;
  const [state, setState] = useState('all');
  const { data, loading, fetchMore, refetch } =
    useAdminSwapOrderConnectionQuery({ variables: { state, payerMixinUuid } });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    adminSwapOrderConnection: {
      nodes: swapOrders,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  const columns: Array<ColumnProps<SwapOrder>> = [
    { dataIndex: 'traceId', key: 'traceId', title: 'Trace ID' },
    {
      dataIndex: 'payer',
      key: 'payer',
      render: (_, swapOrder) => (
        <Space>
          <Avatar src={swapOrder.payer.avatar} />
          <span>{swapOrder.payer.name}</span>
          <span>({swapOrder.payer.mixinId})</span>
        </Space>
      ),
      title: 'Payer',
    },
    { dataIndex: 'state', key: 'state', title: 'State' },
    {
      dataIndex: 'funds',
      key: 'funds',
      render: (funds, swapOrder) => (
        <Space>
          <Avatar src={swapOrder.payAsset.iconUrl} />
          <span>{funds}</span>
        </Space>
      ),
      title: 'funds',
    },
    {
      dataIndex: 'amount',
      key: 'amount',
      render: (amount, swapOrder) => (
        <Space>
          <Avatar src={swapOrder.fillAsset.iconUrl} />
          <span>{amount || '-'}</span>
        </Space>
      ),
      title: 'amount',
    },
    {
      dataIndex: 'minAmount',
      key: 'minAmount',
      render: (minAmount) => minAmount || '-',
      title: 'minAmount',
    },
    { dataIndex: 'createdAt', key: 'createdAt', title: 'createdAt' },
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
            <Select.Option value='swapping'>Swapping</Select.Option>
            <Select.Option value='rejected'>Rejected</Select.Option>
            <Select.Option value='swapped'>Swapped</Select.Option>
            <Select.Option value='order_placed'>Order Placed</Select.Option>
            <Select.Option value='completed'>Completed</Select.Option>
            <Select.Option value='refunded'>Refunded</Select.Option>
          </Select>
        </div>
        <Button type='primary' onClick={() => refetch()}>
          Refresh
        </Button>
      </div>
      <Table
        scroll={{ x: true }}
        dataSource={swapOrders}
        columns={columns}
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
