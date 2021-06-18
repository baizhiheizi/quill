import { useDebounce } from 'ahooks';
import {
  Form,
  Input,
  InputNumber,
  message,
  Modal,
  Select,
  Space,
  Spin,
} from 'antd';
import {
  Bonus,
  useAdminCreateBonusMutation,
  useAdminUpdateBonusMutation,
  useAdminUserConnectionQuery,
  usePricableCurrenciesQuery,
  User,
} from 'graphqlTypes';
import React, { useEffect, useState } from 'react';

export default function BonusesFormModalComponent(props: {
  visible: boolean;
  onCancel: () => any;
  editingBonus?: Partial<Bonus>;
  refetchBonuses?: () => any;
}) {
  const { visible, onCancel, editingBonus, refetchBonuses } = props;
  const [query, setQuery] = useState(null);
  const [bonusForm] = Form.useForm();
  const debouncedQuery = useDebounce(query, { wait: 500 });
  const { data, loading } = useAdminUserConnectionQuery({
    notifyOnNetworkStatusChange: true,
    variables: { query: debouncedQuery },
  });
  const { data: pricableCurrenciesData } = usePricableCurrenciesQuery();
  const [createBonus] = useAdminCreateBonusMutation({
    update(
      _,
      {
        data: {
          adminCreateBonus: { error },
        },
      },
    ) {
      if (error) {
        message.error(error);
      } else {
        message.success('success');
        bonusForm.resetFields();
        refetchBonuses();
        onCancel();
      }
    },
  });
  const [updateBonus] = useAdminUpdateBonusMutation({
    update(
      _,
      {
        data: {
          adminUpdateBonus: { error },
        },
      },
    ) {
      if (error) {
        message.error(error);
      } else {
        message.success('success');
        bonusForm.resetFields();
        refetchBonuses();
        onCancel();
      }
    },
  });
  useEffect(() => {
    if (editingBonus) {
      bonusForm.setFieldsValue({
        userId: editingBonus.user.id,
        title: editingBonus.title,
        description: editingBonus.description,
        amount: editingBonus.amount,
        assetId: editingBonus.assetId,
      });
    } else {
      bonusForm.resetFields();
    }
  }, [editingBonus]);

  const users = (data && data.adminUserConnection.nodes) || [];
  const pricableCurrencies = pricableCurrenciesData?.pricableCurrencies || [];

  return (
    <Modal
      title={editingBonus ? 'Edit' : 'New'}
      visible={visible}
      onCancel={onCancel}
      onOk={() => bonusForm.submit()}
    >
      <Form
        labelCol={{ span: 6 }}
        form={bonusForm}
        onFinish={(values) => {
          if (editingBonus) {
            updateBonus({
              variables: { input: { ...values, id: editingBonus.id } },
            });
          } else {
            createBonus({ variables: { input: values } });
          }
        }}
      >
        <Form.Item name='userId' label='User' rules={[{ required: true }]}>
          <Select
            showSearch
            placeholder='Search user name/mixinId'
            filterOption={false}
            notFoundContent={loading ? <Spin size='small' /> : null}
            onSearch={(value) => setQuery(value)}
          >
            {users.map((user: Partial<User>) => (
              <Select.Option key={user.id} value={user.id}>
                <Space>
                  <span>{user.name}</span>
                  <span>{user.mixinId}</span>
                </Space>
              </Select.Option>
            ))}
          </Select>
        </Form.Item>
        <Form.Item name='assetId' label='Asset' rules={[{ required: true }]}>
          <Select placeholder='Asset'>
            {pricableCurrencies.map((currency: any) => (
              <Select.Option key={currency.assetId} value={currency.assetId}>
                {currency.symbol}
              </Select.Option>
            ))}
          </Select>
        </Form.Item>
        <Form.Item name='amount' label='Amount' rules={[{ required: true }]}>
          <InputNumber
            className='w-36'
            min={0.000_000_01}
            precision={8}
            step={0.000_001}
            placeholder='0.0'
          />
        </Form.Item>
        <Form.Item name='title' label='Title' rules={[{ required: true }]}>
          <Input />
        </Form.Item>
        <Form.Item name='description' label='Description'>
          <Input.TextArea />
        </Form.Item>
      </Form>
    </Modal>
  );
}
