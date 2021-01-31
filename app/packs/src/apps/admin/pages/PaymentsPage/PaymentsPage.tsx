import { SUPPORTED_TOKENS } from '@/shared';
import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import { Payment as IPayment, useAdminPaymentConnectionQuery } from '@graphql';
import { Avatar, Button, PageHeader, Space, Table } from 'antd';
import { ColumnProps } from 'antd/es/table';
import React from 'react';

export default function PaymentsPage() {
  const { data, loading, fetchMore } = useAdminPaymentConnectionQuery();

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
      render: (_, payment) => (
        <Space>
          <Avatar src={payment.payer.avatarUrl} />
          <span>
            {payment.payer.name}({payment.payer.mixinId})
          </span>
        </Space>
      ),
      title: 'Author',
    },
    {
      dataIndex: 'amount',
      key: 'amount',
      render: (amount, payment) => (
        <Space>
          <Avatar
            src={
              SUPPORTED_TOKENS.find(
                (token) => token.assetId === payment.assetId,
              )?.iconUrl
            }
          />
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
    <div>
      <PageHeader title='Payments' />
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={payments}
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
