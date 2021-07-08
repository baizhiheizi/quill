import { Avatar, Button, Select, Space, Table } from 'antd';
import { ColumnProps } from 'antd/lib/table';
import LoadingComponent from 'apps/admin/components/LoadingComponent/LoadingComponent';
import { usePrsdigg } from 'apps/admin/shared';
import { FOXSWAP_APP_ID } from 'apps/shared';
import {
  MixinNetworkSnapshot,
  useAdminMixinNetworkSnapshotConnectionQuery,
} from 'graphqlTypes';
import React, { useState } from 'react';

export default function MixinNetworkSnapshotsComponent(props: {
  userId?: string;
}) {
  const { appId } = usePrsdigg();
  const { userId } = props;
  const [filter, setFilter] = useState<'input' | 'output' | 'prsdigg' | 'all'>(
    'input',
  );
  const { data, loading, fetchMore, refetch } =
    useAdminMixinNetworkSnapshotConnectionQuery({
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
            <Avatar src={snapshot.opponent.avatar} />
            {snapshot.opponent.name}
            {snapshot.opponent.mixinId}
          </Space>
        ) : snapshot.opponentId === appId ? (
          'PRSDigg'
        ) : snapshot.opponentId === FOXSWAP_APP_ID ? (
          '4swap'
        ) : (
          snapshot.opponentId || 'MTG'
        ),
      title: 'Opponent',
    },
    {
      dataIndex: 'amount',
      key: 'amount',
      render: (amount, snapshot) => (
        <Space>
          <Avatar src={snapshot.currency?.iconUrl} />
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
    <>
      <div className='flex justify-between mb-4'>
        <div className='flex space-x-2'>
          <Select
            style={{ width: 200 }}
            value={filter}
            onChange={(value) => setFilter(value)}
          >
            <Select.Option value='input'>Input</Select.Option>
            <Select.Option value='output'>Output</Select.Option>
            <Select.Option value='prsdigg'>From PRSDigg</Select.Option>
            <Select.Option value='4swap'>4swap</Select.Option>
            <Select.Option value='all'>All</Select.Option>
          </Select>
        </div>
        <Button type='primary' onClick={() => refetch()}>
          Refresh
        </Button>
      </div>
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={snapshots}
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
