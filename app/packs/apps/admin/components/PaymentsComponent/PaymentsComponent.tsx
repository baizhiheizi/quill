import { Avatar, Button, Select, Space, Table } from 'antd';
import { ColumnProps } from 'antd/es/table';
import LoadingComponent from 'apps/admin/components/LoadingComponent/LoadingComponent';
import {
  Payment as IPayment,
  useAdminPaymentConnectionQuery,
} from 'graphqlTypes';
import React, { useState } from 'react';

export default function PaymentsComponent(props: { payerMixinUuid?: string }) {
  const { payerMixinUuid } = props;
  const [state, setState] = useState('all');
  const { data, loading, fetchMore, refetch } = useAdminPaymentConnectionQuery({
    variables: { payerMixinUuid, state },
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    adminPaymentConnection: {
      nodes: payments,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;
  const columns: Array<ColumnProps<IPayment>> = [
    {
      dataIndex: 'traceId',
      key: 'traceId',
      title: 'Trace ID',
    },
    {
      dataIndex: 'payer',
      key: 'payer',
      render: (_, payment) =>
        payment.payer ? (
          <Space>
            <Avatar src={payment.payer.avatar} />
            <span>
              {payment.payer.name}({payment.payer.mixinId})
            </span>
          </Space>
        ) : (
          payment.opponentId
        ),
      title: 'Payer',
    },
    {
      dataIndex: 'amount',
      key: 'amount',
      render: (amount, payment) => (
        <Space>
          <Avatar src={payment.currency.iconUrl} />
          <span>{amount}</span>
        </Space>
      ),
      title: 'Amount',
    },
    {
      dataIndex: 'state',
      key: 'state',
      title: 'state',
    },
    {
      dataIndex: 'decryptedMemo',
      key: 'decryptedMemo',
      title: 'Decrypted Memo',
    },
    {
      dataIndex: 'orderType',
      key: 'orderType',
      render: (_, payment) => (
        <span>{payment.order ? payment.order.orderType : '-'}</span>
      ),
      title: 'orderType',
    },
    {
      dataIndex: 'createdAt',
      key: 'createdAt',
      title: 'Created At',
    },
    {
      dataIndex: 'snapshotId',
      key: 'snapshotId',
      render: (snapshotId) => (
        <a href={`https://mixin.one/snapshots/${snapshotId}`} target='_blank'>
          View
        </a>
      ),
      title: 'Snapshot',
    },
  ];

  return (
    <>
      <div className='flex justify-between mb-4'>
        <div className='flex space-x-4'>
          <Select
            className='w-48'
            value={state}
            onChange={(value) => setState(value)}
          >
            <Select.Option value='all'>All</Select.Option>
            <Select.Option value='paid'>Paid</Select.Option>
            <Select.Option value='completed'>Completed</Select.Option>
            <Select.Option value='refunded'>Refunded</Select.Option>
          </Select>
        </div>
        <Button type='primary' onClick={() => refetch()}>
          Refresh
        </Button>
      </div>
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={payments}
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
