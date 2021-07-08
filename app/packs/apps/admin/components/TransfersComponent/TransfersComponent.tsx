import { Avatar, Button, Select, Space, Table } from 'antd';
import { ColumnProps } from 'antd/es/table';
import LoadingComponent from 'apps/admin/components/LoadingComponent/LoadingComponent';
import { usePrsdigg } from 'apps/admin/shared';
import {
  AdminTransferConnectionQueryHookResult,
  Transfer as ITransfer,
  useAdminTransferConnectionQuery,
} from 'graphqlTypes';
import React, { useState } from 'react';

export default function TransfersComponent(props: {
  itemId?: string;
  itemType?: string;
  sourceId?: string;
  sourceType?: string;
}) {
  const { appId } = usePrsdigg();
  const { itemId, itemType, sourceId, sourceType } = props;
  const [transferType, setTransferType] = useState('all');
  const {
    data,
    loading,
    fetchMore,
    refetch,
  }: AdminTransferConnectionQueryHookResult = useAdminTransferConnectionQuery({
    variables: { itemId, itemType, sourceId, sourceType, transferType },
  });

  if (loading) {
    return <LoadingComponent />;
  }
  const {
    adminTransferConnection: {
      nodes: transfers,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;
  const columns: Array<ColumnProps<ITransfer>> = [
    {
      dataIndex: 'traceId',
      key: 'traceId',
      title: 'Trace ID',
    },
    {
      dataIndex: 'recipient',
      key: 'recipient',
      render: (_, transfer) =>
        transfer.recipient ? (
          <Space>
            <Avatar src={transfer.recipient.avatar} />
            <span>
              {transfer.recipient.name}({transfer.recipient.mixinId})
            </span>
          </Space>
        ) : transfer.opponentId === appId ? (
          'PRSDigg'
        ) : (
          transfer.opponentId || 'MTG'
        ),
      title: 'Recipient',
    },
    {
      dataIndex: 'amount',
      key: 'amount',
      render: (amount, transfer) => (
        <Space>
          <Avatar src={transfer.currency?.iconUrl} />
          <span>{amount}</span>
        </Space>
      ),
      title: 'Amount',
    },
    {
      dataIndex: 'transferType',
      key: 'transferType',
      title: 'transferType',
    },
    {
      dataIndex: 'processedAt',
      key: 'processedAt',
      render: (processedAt) => <span>{processedAt || '-'}</span>,
      title: 'Processed At',
    },
    {
      dataIndex: 'createdAt',
      key: 'createdAt',
      title: 'Created At',
    },
    {
      dataIndex: 'snapshotId',
      key: 'snapshotId',
      render: (snapshotId) => (
        <span>
          {snapshotId ? (
            <a
              href={`https://mixin.one/snapshots/${snapshotId}`}
              target='_blank'
            >
              View
            </a>
          ) : (
            'processing'
          )}
        </span>
      ),
      title: 'Snapshot',
    },
  ];

  return (
    <>
      <div className='flex justify-between mb-4'>
        <div className='flex space-x-4'>
          <Select
            className='w-48'
            value={transferType}
            onChange={(value) => setTransferType(value)}
          >
            <Select.Option value='all'>All</Select.Option>
            <Select.Option value='author_revenue'>Author Revenue</Select.Option>
            <Select.Option value='reader_revenue'>Reader Revenue</Select.Option>
            <Select.Option value='prsdigg_revenue'>
              Prsdigg Revenue
            </Select.Option>
            <Select.Option value='payment_refund'>Payment Refund</Select.Option>
            <Select.Option value='bonus'>Bonus</Select.Option>
            <Select.Option value='swap_change'>Swap Change</Select.Option>
            <Select.Option value='swap_refund'>Swap Refund</Select.Option>
            <Select.Option value='fox_swap'>Fox Swap</Select.Option>
            <Select.Option value='withdraw_balance'>
              Withdraw Balance
            </Select.Option>
          </Select>
        </div>
        <Button type='primary' onClick={() => refetch()}>
          Refresh
        </Button>
      </div>
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={transfers}
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
