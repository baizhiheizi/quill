import { Button, Select, Table } from 'antd';
import { ColumnProps } from 'antd/lib/table';
import LoadingComponent from 'apps/admin/components/LoadingComponent/LoadingComponent';
import {
  PrsTransaction,
  useAdminPrsTransactionConnectionQuery,
} from 'graphqlTypes';
import React, { useState } from 'react';

export function PrsTransactionsComponent() {
  const [type, setType] = useState('all');
  const { data, loading, fetchMore, refetch } =
    useAdminPrsTransactionConnectionQuery({
      variables: { type },
    });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    adminPrsTransactionConnection: {
      nodes: transactions,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  const columns: Array<ColumnProps<PrsTransaction>> = [
    {
      dataIndex: 'id',
      key: 'id',
      title: 'ID',
    },
    {
      dataIndex: 'type',
      key: 'type',
      title: 'type',
    },
    {
      dataIndex: 'userAddress',
      key: 'userAddress',
      render: (_, transition) => transition.userAddress || '-',
      title: 'userAddress',
    },
    {
      dataIndex: 'user',
      key: 'user',
      render: (_, transaction) => (
        <>
          {transaction.prsAccount ? (
            <span>
              {transaction.prsAccount.user.name}(
              {transaction.prsAccount.user.mixinId})
            </span>
          ) : (
            '-'
          )}
        </>
      ),
      title: 'User',
    },
    {
      dataIndex: 'data',
      key: 'data',
      title: 'data',
    },
    {
      dataIndex: 'processedAt',
      key: 'processedAt',
      title: 'Processed At',
    },
    {
      dataIndex: 'createdAt',
      key: 'createdAt',
      title: 'Created At',
    },
  ];

  return (
    <>
      <div className='flex justify-between mb-4'>
        <div className='flex space-x-4'>
          <Select
            className='w-72'
            value={type}
            onChange={(value) => setType(value)}
          >
            <Select.Option value='all'>All</Select.Option>
            <Select.Option value='ArticleSnapshotPrsTransaction'>
              Article
            </Select.Option>
            <Select.Option value='PrsAccountAuthorizationTransaction'>
              Authorization
            </Select.Option>
          </Select>
        </div>
        <Button type='primary' onClick={() => refetch()}>
          Refresh
        </Button>
      </div>
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={transactions}
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
                type,
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
