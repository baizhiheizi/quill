import {
  AdminUserConnectionQueryHookResult,
  useAdminUserConnectionQuery,
  User as IUser,
} from '@graphql';
import {
  Avatar,
  Button,
  Col,
  Input,
  PageHeader,
  Popover,
  Row,
  Select,
  Space,
} from 'antd';
import Table, { ColumnProps } from 'antd/lib/table';
import React, { useState } from 'react';
import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import { useDebounce } from 'ahooks';

export default function UsersPage() {
  const [query, setQuery] = useState('');
  const [orderBy, setOrderBy] = useState('default');
  const debouncedQuery = useDebounce(query, { wait: 500 });
  return (
    <div>
      <PageHeader title='Users' />
      <Row gutter={16} style={{ marginBottom: '1rem' }}>
        <Col>
          <Select
            style={{ width: 200 }}
            value={orderBy}
            onChange={(value) => setOrderBy(value)}
          >
            <Select.Option value='default'>Default</Select.Option>
            <Select.Option value='revenue_total'>Revenue Total</Select.Option>
            <Select.Option value='payment_total'>Payment Total</Select.Option>
            <Select.Option value='articles_count'>Articles Count</Select.Option>
            <Select.Option value='comment_count'>Comments Count</Select.Option>
          </Select>
        </Col>
        <Col>
          <Input
            value={query}
            onChange={(e) => setQuery(e.currentTarget.value)}
          />
        </Col>
      </Row>
      <UsersComponent orderBy={orderBy} query={debouncedQuery} />
    </div>
  );
}

export function UsersComponent(props: { query?: string; orderBy?: string }) {
  const { query, orderBy } = props;
  const {
    data,
    loading,
    fetchMore,
  }: AdminUserConnectionQueryHookResult = useAdminUserConnectionQuery({
    variables: { query, orderBy },
  });

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
      dataIndex: 'revenueTotal',
      key: 'revenueTotal',
      title: 'Revenue Total',
    },
    {
      dataIndex: 'paymentTotal',
      key: 'paymentTotal',
      title: 'Payment Total',
    },
    {
      dataIndex: 'createdAt',
      key: 'createdAt',
      title: 'Created At',
    },
  ];

  return (
    <div>
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={users}
        rowKey='mixinId'
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
