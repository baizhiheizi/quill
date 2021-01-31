import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import {
  Bonus,
  useAdminBonusConnectionQuery,
  useAdminDeliverBonusMutation,
} from '@graphql';
import {
  Avatar,
  Button,
  Divider,
  message,
  PageHeader,
  Popconfirm,
  Space,
  Table,
} from 'antd';
import { ColumnProps } from 'antd/es/table';
import React, { useState } from 'react';
import BonusesFormModalComponent from './components/BonusFormModalComponent';

export default function BonusesPage() {
  const [modalVisible, setModalVisible] = useState(false);
  const [editing, setEditing] = useState(null);

  const { data, loading, fetchMore, refetch } = useAdminBonusConnectionQuery();
  const [deliverBonus] = useAdminDeliverBonusMutation({
    update(
      _,
      {
        data: {
          adminDeliverBonus: { state },
        },
      },
    ) {
      if (state !== 'drafted') {
        message.success('Delivered!');
      }
    },
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    adminBonusConnection: {
      nodes: bonuses,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  const columns: Array<ColumnProps<Bonus>> = [
    { dataIndex: 'id', key: 'id', title: 'ID' },
    {
      dataIndex: 'user',
      key: 'user',
      render: (_, bonus) => (
        <Space>
          <Avatar src={bonus.user.avatarUrl} />
          <span>{bonus.user.name}</span>
        </Space>
      ),
      title: 'User',
    },
    { dataIndex: 'title', key: 'title', title: 'Title' },
    {
      dataIndex: 'description',
      key: 'description',
      render: (description) => <div>{description || '-'}</div>,
      title: 'Description',
    },
    { dataIndex: 'amount', key: 'amount', title: 'Amount' },
    { dataIndex: 'state', key: 'state', title: 'state' },
    { dataIndex: 'createdAt', key: 'createdAt', title: 'createdAt' },
    {
      dataIndex: 'snapshotId',
      key: 'snapshotId',
      render: (_, bonus) =>
        bonus.transfer && bonus.transfer.snapshotId ? (
          <a
            href={`https://mixin/one/snapshots/${bonus.transfer.snapshotId}`}
            target='_blank'
          >
            SnapshotId
          </a>
        ) : (
          '-'
        ),
      title: 'snapshotId',
    },
    {
      dataIndex: 'actions',
      key: 'actions',
      render: (_, bonus) => (
        <span>
          <Popconfirm
            disabled={bonus.state !== 'drafted'}
            title='Are you sure to deliver bonus to user?'
            onConfirm={() =>
              deliverBonus({ variables: { input: { id: bonus.id } } })
            }
          >
            <Button
              type='link'
              disabled={bonus.state !== 'drafted'}
              size='small'
            >
              Deliver
            </Button>
          </Popconfirm>
          <Divider type='vertical' />
          <Button
            disabled={bonus.state !== 'drafted'}
            onClick={() => {
              setEditing(bonus);
              setModalVisible(true);
            }}
            type='link'
            size='small'
          >
            Edit
          </Button>
        </span>
      ),
      title: 'Actions',
    },
  ];
  return (
    <div>
      <PageHeader title='Bonuses' />
      <div style={{ marginBottom: '1rem' }}>
        <Button
          type='primary'
          onClick={() => {
            setEditing(null);
            setModalVisible(true);
          }}
        >
          New
        </Button>
        <BonusesFormModalComponent
          visible={modalVisible}
          editingBonus={editing}
          onCancel={() => setModalVisible(false)}
          refetchBonuses={refetch}
        />
      </div>
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={bonuses}
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
