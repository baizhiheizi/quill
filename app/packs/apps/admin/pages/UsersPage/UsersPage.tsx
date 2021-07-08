import { useDebounce } from 'ahooks';
import {
  Avatar,
  Button,
  Col,
  Divider,
  Input,
  PageHeader,
  Popconfirm,
  Popover,
  Row,
  Select,
  Space,
  Table,
} from 'antd';
import { ColumnProps } from 'antd/lib/table';
import LoadingComponent from 'apps/admin/components/LoadingComponent/LoadingComponent';
import {
  AdminUserConnectionQueryHookResult,
  useAdminBanUserMutation,
  useAdminUnbanUserMutation,
  useAdminUserConnectionQuery,
  User as IUser,
} from 'graphqlTypes';
import React, { useState } from 'react';
import { Link } from 'react-router-dom';

export default function UsersPage() {
  const [query, setQuery] = useState('');
  const [orderBy, setOrderBy] = useState('default');
  const [filter, setFilter] = useState('without_banned');
  const debouncedQuery = useDebounce(query, { wait: 500 });
  return (
    <div>
      <PageHeader title='Users' />
      <Row gutter={16} className='mb-4'>
        <Col>
          <Select
            style={{ width: 200 }}
            value={orderBy}
            onChange={(value) => setOrderBy(value)}
          >
            <Select.Option value='default'>Default Order</Select.Option>
            <Select.Option value='orders_total'>
              Orders Total DESC
            </Select.Option>
            <Select.Option value='revenue_total'>
              Revenue Total DESC
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
    refetch,
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
          <Avatar src={user.avatar} />
          {name}
        </Space>
      ),
      title: 'Name',
    },
    {
      dataIndex: 'phone',
      key: 'phone',
      render: (_, user) => user.phone || '-',
      title: 'Phone',
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
      dataIndex: 'boughtArticlesCount',
      key: 'boughtArticlesCount',
      render: (_, user) => user.statistics.boughtArticlesCount,
      title: 'Bought Articles',
    },
    {
      dataIndex: 'revenue',
      key: 'revenue',
      render: (_, user) => (
        <>{`${user.statistics.revenueTotalBtc.toFixed(
          8,
        )} ($${user.statistics.revenueTotalUsd.toFixed(2)})`}</>
      ),
      title: 'Revenue(BTC/USD)',
    },
    {
      dataIndex: 'payment',
      key: 'payment',
      render: (_, user) => (
        <>{`${user.statistics.paymentTotalBtc.toFixed(
          8,
        )} ($${user.statistics.paymentTotalUsd.toFixed(2)})`}</>
      ),
      title: 'Payment(BTC/USD)',
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
          <Link to={`/users/${user.mixinId}`}>Detail</Link>
          <Divider type='vertical' />
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
        </span>
      ),
    },
  ];

  return (
    <>
      <div className='flex justify-end mb-4'>
        <Button type='primary' onClick={() => refetch()}>
          Refresh
        </Button>
      </div>
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={users}
        rowKey='mixinId'
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
    </>
  );
}
