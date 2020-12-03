import { SUPPORTED_TOKENS } from '@/shared';
import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import { usePrsdigg } from '@admin/shared';
import {
  AdminTransferConnectionQueryHookResult,
  Transfer as ITransfer,
  useAdminTransferConnectionQuery,
} from '@graphql';
import { Avatar, Button, Space } from 'antd';
import Table, { ColumnProps } from 'antd/lib/table';
import React from 'react';

export default function TransfersComponent(props: {
  itemId?: string;
  itemType?: string;
  sourceId?: string;
  sourceType?: string;
}) {
  const { appId } = usePrsdigg();
  const { itemId, itemType, sourceId, sourceType } = props;
  const {
    data,
    loading,
    fetchMore,
  }: AdminTransferConnectionQueryHookResult = useAdminTransferConnectionQuery({
    variables: { itemId, itemType, sourceId, sourceType },
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
            <Avatar src={transfer.recipient.avatarUrl} />
            <span>
              {transfer.recipient.name}({transfer.recipient.mixinId})
            </span>
          </Space>
        ) : transfer.opponentId === appId ? (
          'PRSDigg'
        ) : (
          transfer.opponentId
        ),
      title: 'Recipient',
    },
    {
      dataIndex: 'amount',
      key: 'amount',
      render: (amount, transfer) => (
        <Space>
          <Avatar
            src={
              SUPPORTED_TOKENS.find(
                (token) => token.assetId === transfer.assetId,
              )?.iconUrl
            }
          />
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
    <div>
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={transfers}
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
