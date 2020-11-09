import { MixinMessage, useAdminMixinMessageConnectionQuery } from '@/graphql';
import React from 'react';
import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import { ColumnProps } from 'antd/es/table';
import { Avatar, Button, PageHeader, Space, Table } from 'antd';

export default function MixinMessagesPage() {
  const { data, loading, fetchMore } = useAdminMixinMessageConnectionQuery();

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    adminMixinMessageConnection: {
      nodes: messages,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  const columns: Array<ColumnProps<MixinMessage>> = [
    {
      dataIndex: 'action',
      key: 'action',
      title: 'Action',
    },
    {
      dataIndex: 'category',
      key: 'category',
      title: 'category',
    },
    {
      dataIndex: 'user',
      key: 'user',
      render: (_, message) =>
        message.user ? (
          <Space>
            <Avatar src={message.user.avatarUrl} />
            {message.user.name}
            {message.user.mixinId}
          </Space>
        ) : (
          message.userId
        ),
      title: 'User',
    },
    {
      dataIndex: 'content',
      key: 'content',
      title: 'content',
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
      <PageHeader title='Mixin Messages' />
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={messages}
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
                const connection = fetchMoreResult.adminMixinMessageConnection;
                connection.nodes = prev.adminMixinMessageConnection.nodes.concat(
                  connection.nodes,
                );
                return Object.assign({}, prev, {
                  adminMixinMessageConnection: connection,
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
