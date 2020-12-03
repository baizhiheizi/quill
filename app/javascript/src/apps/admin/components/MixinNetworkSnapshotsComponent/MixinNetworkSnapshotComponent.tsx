import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import { usePrsdigg } from '@admin/shared';
import {
  MixinNetworkSnapshot,
  useAdminMixinNetworkSnapshotConnectionQuery,
} from '@graphql';
import { FOXSWAP_APP_ID, SUPPORTED_TOKENS } from '@shared';
import { Avatar, Button, Space, Table } from 'antd';
import { ColumnProps } from 'antd/lib/table';
import React from 'react';

export default function MixinNetworkSnapshotsComponent(props: {
  filter?: 'input' | 'output' | 'prsdigg' | 'all';
  userId?: string;
}) {
  const { appId } = usePrsdigg();
  const { userId, filter = 'all' } = props;
  const {
    data,
    loading,
    fetchMore,
  } = useAdminMixinNetworkSnapshotConnectionQuery({
    variables: { filter, userId },
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    adminMixinNetworkSnapshotConnection: {
      nodes: snapshots,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;
  const columns: Array<ColumnProps<MixinNetworkSnapshot>> = [
    {
      dataIndex: 'traceId',
      key: 'traceId',
      title: 'traceId',
    },
    {
      dataIndex: 'wallet',
      key: 'wallet',
      render: (_, snapshot) =>
        snapshot.article ? (
          <a
            href={`https://prsdigg.com/articles/${snapshot.article.uuid}`}
            target='_blank'
          >
            {snapshot.article.title}
          </a>
        ) : snapshot.userId === appId ? (
          'PRSDigg'
        ) : snapshot.userId === FOXSWAP_APP_ID ? (
          '4swap'
        ) : (
          snapshot.userId
        ),
      title: 'Wallet',
    },
    {
      dataIndex: 'opponent',
      key: 'opponent',
      render: (_, snapshot) =>
        snapshot.opponent ? (
          <Space>
            <Avatar src={snapshot.opponent.avatarUrl} />
            {snapshot.opponent.name}
            {snapshot.opponent.mixinId}
          </Space>
        ) : snapshot.opponentId === appId ? (
          'PRSDigg'
        ) : snapshot.opponentId === FOXSWAP_APP_ID ? (
          '4swap'
        ) : (
          snapshot.opponentId
        ),
      title: 'Opponent',
    },
    {
      dataIndex: 'amount',
      key: 'amount',
      render: (amount, snapshot) => (
        <Space>
          <Avatar
            src={
              SUPPORTED_TOKENS.find(
                (token) => token.assetId === snapshot.assetId,
              )?.iconUrl
            }
          />
          <span>{amount}</span>
        </Space>
      ),
      title: 'amount',
    },
    {
      dataIndex: 'processedAt',
      key: 'processedAt',
      title: 'processedAt',
    },
    {
      dataIndex: 'createdAt',
      key: 'createdAt',
      title: 'createdAt',
    },
  ];

  return (
    <div>
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={snapshots}
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
