import { Avatar, Input, message, Modal, Table } from 'antd';
import { ColumnProps } from 'antd/es/table';
import {
  Asset,
  useAdminWalletBalanceQuery,
  useAdminWithdrawBalanceMutation,
} from 'graphqlTypes';
import React, { useState } from 'react';
import LoadingComponent from '../LoadingComponent/LoadingComponent';

export default function WalletBalanceComponent(props: { userId?: string }) {
  const { userId } = props;
  const { loading, data, refetch } = useAdminWalletBalanceQuery({
    fetchPolicy: 'network-only',
    variables: { userId },
  });
  const [withdrawAmount, setWithdrawAmount] = useState('');
  const [selectedAsset, setSelectedAsset] = useState<Asset>();
  const [withdrawBalance] = useAdminWithdrawBalanceMutation({
    update(_, { data: { adminWithdrawBalance } }) {
      if (adminWithdrawBalance) {
        message.success('Withdrawing');
        refetch();
      } else {
        message.error('failed');
      }
      setSelectedAsset(null);
    },
  });

  if (loading) {
    return <LoadingComponent />;
  }
  const { adminWalletBalance: assets } = data;

  const columns: Array<ColumnProps<Asset>> = [
    { title: 'asset ID', dataIndex: 'assetId', key: 'assetId' },
    {
      dataIndex: 'iconUrl',
      key: 'iconUrl',
      render: (text, record) => <Avatar src={text}>{record.symbol[0]}</Avatar>,
      title: 'icon',
    },
    { title: 'Symbol', dataIndex: 'symbol', key: 'symbol' },
    { title: 'Balance', dataIndex: 'balance', key: 'balance' },
    {
      dataIndex: 'priceUsd',
      key: 'priceUsd',
      render: (text, record) => {
        return parseFloat(record.balance) > 0
          ? `$ ${parseFloat(text) * parseFloat(record.balance)}`
          : 0;
      },
      title: 'Value',
    },
    {
      dataIndex: 'actions',
      key: 'actions',
      render: (_, record) => (
        <div className='flex space-x-1'>
          <div
            className='cursor-pointer'
            onClick={() => {
              setWithdrawAmount(record.balance);
              setSelectedAsset(record);
            }}
          >
            Withdraw
          </div>
        </div>
      ),
      title: 'Actions',
    },
  ];
  return (
    <>
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={assets}
        rowKey='assetId'
        loading={loading}
        pagination={{ pageSize: 50 }}
        size='small'
      />
      <Modal
        title='Withdraw to OWNER'
        closable={false}
        visible={Boolean(selectedAsset)}
        onCancel={() => setSelectedAsset(null)}
        onOk={() =>
          withdrawBalance({
            variables: {
              input: {
                assetId: selectedAsset?.assetId,
                amount: withdrawAmount,
              },
            },
          })
        }
      >
        <div className='flex'>
          <Input
            value={withdrawAmount}
            onChange={(e) => setWithdrawAmount(e.target.value)}
          />
        </div>
      </Modal>
    </>
  );
}
