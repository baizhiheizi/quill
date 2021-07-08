import { useDebounce } from 'ahooks';
import { Avatar, Button, Input, PageHeader, Select, Space, Table } from 'antd';
import { ColumnProps } from 'antd/lib/table';
import LoadingComponent from 'apps/admin/components/LoadingComponent/LoadingComponent';
import { PrsAccount, useAdminPrsAccountConnectionQuery } from 'graphqlTypes';
import React, { useState } from 'react';

export default function PrsAccountsPage() {
  const [query, setQuery] = useState('');
  const [status, setStatus] = useState('all');
  const debouncedQuery = useDebounce(query, { wait: 500 });
  return (
    <>
      <PageHeader title='Prs Accounts' />
      <div className='flex mb-4 space-x-4'>
        <Select
          className='w-72'
          value={status}
          onChange={(value) => setStatus(value)}
        >
          <Select.Option value='all'>All</Select.Option>
          <Select.Option value='created'>Created</Select.Option>
          <Select.Option value='registered'>Registered</Select.Option>
          <Select.Option value='allowing'>Allowing</Select.Option>
          <Select.Option value='allowed'>Allowed</Select.Option>
          <Select.Option value='denying'>Denying</Select.Option>
          <Select.Option value='denied'>Denied</Select.Option>
        </Select>
        <Input
          className='w-72'
          value={query}
          placeholder='account/name/mixinId'
          onChange={(e) => setQuery(e.currentTarget.value)}
        />
      </div>
      <PrsAccountsComponent query={debouncedQuery} status={status} />
    </>
  );
}

export function PrsAccountsComponent(props: {
  query?: string;
  status?: string;
}) {
  const { query, status } = props;
  const { data, loading, fetchMore, refetch } =
    useAdminPrsAccountConnectionQuery({
      variables: { query, status },
    });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    adminPrsAccountConnection: {
      nodes: accounts,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  const columns: Array<ColumnProps<PrsAccount>> = [
    {
      dataIndex: 'id',
      key: 'id',
      title: 'ID',
    },
    {
      dataIndex: 'account',
      key: 'account',
      render: (text) => text || '-',
      title: 'Account',
    },
    {
      dataIndex: 'user',
      key: 'user',
      render: (_, account) => (
        <Space>
          <Avatar src={account.user.avatar} />
          <span>
            {account.user.name}({account.user.mixinId})
          </span>
        </Space>
      ),
      title: 'User',
    },
    {
      dataIndex: 'status',
      key: 'status',
      title: 'Status',
    },
    {
      dataIndex: 'createdAt',
      key: 'createdAt',
      title: 'Created At',
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
        dataSource={accounts}
        rowKey='id'
        pagination={false}
        size='small'
      />
      <div className='mb-4 text-center'>
        <Button
          type='link'
          loading={loading}
          disabled={!hasNextPage}
          onClick={() => {
            fetchMore({
              variables: {
                status,
                query,
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
