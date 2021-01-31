import { SUPPORTED_TOKENS } from '@/shared';
import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import { SwapOrder, useAdminSwapOrderConnectionQuery } from '@graphql';
import { Avatar, Button, PageHeader, Space, Table } from 'antd';
import { ColumnProps } from 'antd/es/table';
import React from 'react';

export default function SwapOrdersPage() {
  const { data, loading, fetchMore } = useAdminSwapOrderConnectionQuery();
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
    {
      dataIndex: 'funds',
      key: 'funds',
      render: (funds, swapOrder) => (
        <Space>
          <Avatar
            src={
              SUPPORTED_TOKENS.find(
                (token) => token.assetId === swapOrder.payAssetId,
              )?.iconUrl
            }
          />
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
          <Avatar
            src={
              SUPPORTED_TOKENS.find(
                (token) => token.assetId === swapOrder.fillAssetId,
              )?.iconUrl
            }
          />
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
    <div>
      <PageHeader title='Swap Orders' />
      <Table
        scroll={{ x: true }}
        dataSource={swapOrders}
        columns={columns}
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
