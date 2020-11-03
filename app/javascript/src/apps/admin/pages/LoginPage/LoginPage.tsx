import { useAdminLoginMutation } from '@/graphql';
import { ClockCircleOutlined, UserOutlined } from '@ant-design/icons';
import { Button, Form, Input, Layout, message } from 'antd';
import React from 'react';

const { Content } = Layout;

export default function LoginPage() {
  const [login] = useAdminLoginMutation({
    update(
      _,
      {
        data: {
          adminLogin: { error },
        },
      },
    ) {
      if (error) {
        message.error(error);
      } else {
        location.replace('/admin');
      }
    },
  });

  return (
    <Layout className='layout'>
      <Content style={{ display: 'flex', minHeight: '100vh' }}>
        <Form
          onFinish={(values: any) => {
            login({ variables: { input: values } });
          }}
          style={{ width: 300, margin: 'auto' }}
        >
          <Form.Item
            name='name'
            rules={[{ required: true, message: 'Username' }]}
          >
            <Input
              prefix={<UserOutlined style={{ color: 'rgba(0,0,0,.25)' }} />}
              placeholder='Username'
            />
          </Form.Item>
          <Form.Item
            name='password'
            rules={[{ required: true, message: 'Password' }]}
          >
            <Input
              prefix={
                <ClockCircleOutlined style={{ color: 'rgba(0,0,0,.25)' }} />
              }
              type='password'
              placeholder='Password'
            />
          </Form.Item>
          <Form.Item>
            <Button
              loading={false}
              type='primary'
              htmlType='submit'
              className='login-form-button'
            >
              Log in
            </Button>
          </Form.Item>
        </Form>
      </Content>
    </Layout>
  );
}
