import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import { MixinMessage, useAdminMixinMessageConnectionQuery } from '@graphql';
import { Avatar, Button, PageHeader, Space, Table } from 'antd';
import { ColumnProps } from 'antd/es/table';
import React from 'react';

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
      render: (content) => <div style={{ maxWidth: '100%' }}>{content}</div>,
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
        rowKey='id'
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
