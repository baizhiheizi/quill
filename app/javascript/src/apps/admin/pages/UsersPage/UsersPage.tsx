import {
  AdminUserConnectionQueryHookResult,
  useAdminUserConnectionQuery,
  User as IUser,
} from '@graphql';
import { Avatar, Button, PageHeader, Popover, Space } from 'antd';
import Table, { ColumnProps } from 'antd/lib/table';
import React from 'react';
import LoadingComponent from '../../components/LoadingComponent/LoadingComponent';

export default function UsersPage() {
  const {
    data,
    loading,
    fetchMore,
  }: AdminUserConnectionQueryHookResult = useAdminUserConnectionQuery();

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    adminUserConnection: {
      nodes: users,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  const columns: Array<ColumnProps<IUser>> = [
    {
      dataIndex: 'mixinId',
      key: 'mixinId',
      render: (mixinId, user) => (
        <Popover title='mixin UUID' content={user.mixinUuid}>
          {mixinId}
        </Popover>
      ),
      title: 'Mixin ID',
    },
    {
      dataIndex: 'name',
      key: 'name',
      render: (name, user) => (
        <Space>
          <Avatar src={user.avatarUrl} />
          {name}
        </Space>
      ),
      title: 'Name',
    },
    {
      dataIndex: 'mixinUuid',
      key: 'mixinUuid',
      title: 'Mixin UUID',
    },
    {
      dataIndex: 'articlesCount',
      key: 'articlesCount',
      title: 'Articles',
    },
    {
      dataIndex: 'commentsCount',
      key: 'commentsCount',
      title: 'Comments',
    },
    {
      dataIndex: 'authorRevenueAmount',
      key: 'authorRevenueAmount',
      title: 'Author Revenue',
    },
    {
      dataIndex: 'readerRevenueAmount',
      key: 'readerRevenueAmount',
      title: 'Reader Revenue',
    },
    {
      dataIndex: 'paymentsTotal',
      key: 'paymentsTotal',
      title: 'Payments Total',
    },
    {
      dataIndex: 'createdAt',
      key: 'createdAt',
      title: 'Created At',
    },
  ];

  return (
    <div>
      <PageHeader title='Users' />
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={users}
        rowKey='uuid'
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
                const connection = fetchMoreResult.adminUserConnection;
                connection.nodes = prev.adminUserConnection.nodes.concat(
                  connection.nodes,
                );
                return Object.assign({}, prev, {
                  adminUserConnection: connection,
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
