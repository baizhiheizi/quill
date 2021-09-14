import { Button, Form, Input, message } from 'antd';
import LoadingComponent from 'apps/shared/components/LoadingComponent/LoadingComponent';
import {
  useCurrentUserQuery,
  useSyncUserProfileMutation,
  useUpdateUserProfileMutation,
} from 'graphqlTypes';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function ProfileComponent() {
  const { loading, data } = useCurrentUserQuery({
    fetchPolicy: 'network-only',
  });
  const { t } = useTranslation();
  const [form] = Form.useForm();
  const [updateUserProfile, { loading: updating }] =
    useUpdateUserProfileMutation({
      update: (_, { data: { updateUserProfile: success } }) => {
        if (success) {
          message.success(t('success_updated'));
        } else {
          message.error(t('failed_to_save'));
        }
      },
    });
  const [syncUserProfile, { loading: syncing }] = useSyncUserProfileMutation({
    update: () => {
      message.success(t('success_updated'));
    },
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const { currentUser } = data;

  return (
    <>
      <Form
        form={form}
        labelCol={{ span: 8 }}
        wrapperCol={{ span: 16 }}
        initialValues={{
          uid: currentUser.uid,
        }}
        onFinish={(values) => {
          updateUserProfile({ variables: { input: { ...values } } });
        }}
      >
        <Form.Item label={t('name')}>
          <Input value={currentUser.name} disabled />
        </Form.Item>
        <Form.Item label={t('avatar')}>
          <img src={currentUser.avatar} className='w-12 h-12 rounded-full' />
        </Form.Item>
        <Form.Item label={t('bio')}>
          <Input.TextArea value={currentUser.bio} disabled />
        </Form.Item>
        <Form.Item wrapperCol={{ md: { offset: 8, span: 16 } }}>
          <Button
            type='primary'
            ghost
            loading={syncing}
            onClick={() => syncUserProfile({ variables: { input: {} } })}
          >
            {t('sync')}
          </Button>
        </Form.Item>
        <Form.Item name='uid' label='ID' rules={[{ required: true }]}>
          <Input addonBefore={`${location.origin}/users/`} />
        </Form.Item>
        <Form.Item wrapperCol={{ md: { offset: 8, span: 16 } }}>
          <Button type='primary' htmlType='submit' loading={updating}>
            {t('update')}
          </Button>
        </Form.Item>
      </Form>
    </>
  );
}
