import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import {
  AdminUserConnectionQueryHookResult,
  useAdminBanUserMutation,
  useAdminUnbanUserMutation,
  useAdminUserConnectionQuery,
  User as IUser,
} from '@graphql';
import { useDebounce } from 'ahooks';
import {
  Avatar,
  Button,
  Col,
  Input,
  PageHeader,
  Popconfirm,
  Popover,
  Row,
  Select,
  Space,
} from 'antd';
import Table, { ColumnProps } from 'antd/lib/table';
import React, { useState } from 'react';

export default function UsersPage() {
  const [query, setQuery] = useState('');
  const [orderBy, setOrderBy] = useState('default');
  const [filter, setFilter] = useState('without_banned');
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
            <Select.Option value='default'>Default Order</Select.Option>
            <Select.Option value='revenue_total'>
              Revenue Total DESC
            </Select.Option>
            <Select.Option value='payment_total'>
              Payment Total DESC
            </Select.Option>
            <Select.Option value='articles_count'>
              Articles Count DESC
            </Select.Option>
            <Select.Option value='comments_count'>
              Comments Count DESC
            </Select.Option>
          </Select>
        </Col>
        <Col>
          <Select
            style={{ width: 200 }}
            value={filter}
            onChange={(value) => setFilter(value)}
          >
            <Select.Option value='without_banned'>Without Banned</Select.Option>
            <Select.Option value='only_banned'>Only Banned</Select.Option>
            <Select.Option value='all'>All</Select.Option>
          </Select>
        </Col>
        <Col>
          <Input
            value={query}
            placeholder='Query user name/mixinId'
            onChange={(e) => setQuery(e.currentTarget.value)}
          />
        </Col>
      </Row>
      <UsersComponent
        orderBy={orderBy}
        query={debouncedQuery}
        filter={filter}
      />
    </div>
  );
}

export function UsersComponent(props: {
  query?: string;
  orderBy?: string;
  filter?: string;
}) {
  const { query, orderBy, filter } = props;
  const {
    data,
    loading,
    fetchMore,
  }: AdminUserConnectionQueryHookResult = useAdminUserConnectionQuery({
    variables: { query, orderBy, filter },
  });
  const [adminBanUser] = useAdminBanUserMutation();
  const [adminUnbanUser] = useAdminUnbanUserMutation();

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
      render: (_, user) => user.statistics.articlesCount,
      title: 'Articles',
    },
    {
      dataIndex: 'commentsCount',
      key: 'commentsCount',
      render: (_, user) => user.statistics.commentsCount,
      title: 'Comments',
    },
    {
      dataIndex: 'revenueTotal',
      key: 'revenueTotal',
      render: (_, user) => user.statistics.revenueTotal,
      title: 'Revenue Total',
    },
    {
      dataIndex: 'paymentTotal',
      key: 'paymentTotal',
      render: (_, user) => user.statistics.paymentTotal,
      title: 'Payment Total',
    },
    {
      dataIndex: 'bannedAt',
      key: 'bannedAt',
      render: (bannedAt) => bannedAt || '-',
      title: 'Banned At',
    },
    {
      dataIndex: 'createdAt',
      key: 'createdAt',
      title: 'Created At',
    },
    {
      dataIndex: 'Actions',
      key: 'actions',
      render: (_, user) => (
        <span>
          {user.bannedAt ? (
            <Popconfirm
              title='Are you sure to unBan this user?'
              onConfirm={() =>
                adminUnbanUser({
                  variables: { input: { id: user.id } },
                })
              }
            >
              <Button type='link'>unBan</Button>
            </Popconfirm>
          ) : (
            <Popconfirm
              title='Are you sure to BAN this user?'
              onConfirm={() =>
                adminBanUser({
                  variables: { input: { id: user.id } },
                })
              }
            >
              <Button type='link'>Ban</Button>
            </Popconfirm>
          )}
        </span>
      ),
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
              variables: {
                filter,
                query,
                orderBy,
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
