import { SwapOrder, useAdminSwapOrderConnectionQuery } from '@graphql';
import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import { Avatar, PageHeader, Space, Table } from 'antd';
import { ColumnProps } from 'antd/es/table';
import React from 'react';

export default function SwapOrdersPage() {
  const { data, loading } = useAdminSwapOrderConnectionQuery();
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
          <Avatar src={swapOrder.payer.avatarUrl} />
          <span>{swapOrder.payer.name}</span>
          <span>({swapOrder.payer.mixinId})</span>
        </Space>
      ),
      title: 'Payer',
    },
    { dataIndex: 'state', key: 'state', title: 'State' },
    { dataIndex: 'fill', key: 'fill', title: 'fill' },
    { dataIndex: 'amount', key: 'amount', title: 'amount' },
    { dataIndex: 'minAmount', key: 'minAmount', title: 'minAmount' },
    { dataIndex: 'createdAt', key: 'createdAt', title: 'createdAt' },
  ];

  return (
    <div>
      <PageHeader title='Swap Orders' />
      <Table
        scroll={{ x: true }}
        dataSource={swapOrders}
        columns={columns}
        rowKey='traceId'
        pagination={false}
      />
    </div>
  );
}
