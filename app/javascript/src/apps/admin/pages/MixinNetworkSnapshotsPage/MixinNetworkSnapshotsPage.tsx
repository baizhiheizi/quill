import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import { usePrsdigg } from '@admin/shared';
import {
  MixinNetworkSnapshot,
  useAdminMixinNetworkSnapshotConnectionQuery,
} from '@graphql';
import {
  Avatar,
  Button,
  Col,
  PageHeader,
  Row,
  Select,
  Space,
  Table,
} from 'antd';
import { ColumnProps } from 'antd/lib/table';
import React, { useState } from 'react';

export default function MixinNetworkSnapshotsPage() {
  const { appId } = usePrsdigg();
  const [filter, setFilter] = useState('input');
  const {
    data,
    loading,
    fetchMore,
  } = useAdminMixinNetworkSnapshotConnectionQuery({ variables: { filter } });

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
      dataIndex: 'opponent',
      key: 'opponent',
      render: (_, snapshot) =>
        snapshot.opponent ? (
          <Space>
            <Avatar src={snapshot.opponent.avatarUrl} />
            {snapshot.opponent.name}
            {snapshot.opponent.mixinId}
          </Space>
        ) : (
          snapshot.opponentId
        ),
      title: 'Opponent',
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
        ) : (
          snapshot.userId
        ),
      title: 'Wallet',
    },
    {
      dataIndex: 'amount',
      key: 'amount',
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
      <PageHeader title='Mixin Network Snapshot' />
      <Row gutter={16} style={{ marginBottom: '1rem' }}>
        <Col>
          <Select
            style={{ width: 200 }}
            value={filter}
            onChange={(value) => setFilter(value)}
          >
            <Select.Option value='input'>Input</Select.Option>
            <Select.Option value='output'>Output</Select.Option>
            <Select.Option value='prsdigg'>PRSDigg</Select.Option>
            <Select.Option value='all'>All</Select.Option>
          </Select>
        </Col>
      </Row>
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
              updateQuery: (prev, { fetchMoreResult }) => {
                if (!fetchMoreResult) {
                  return prev;
                }
                const connection =
                  fetchMoreResult.adminMixinNetworkSnapshotConnection;
                connection.nodes = prev.adminMixinNetworkSnapshotConnection.nodes.concat(
                  connection.nodes,
                );
                return Object.assign({}, prev, {
                  adminMixinNetworkSnapshotConnection: connection,
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
