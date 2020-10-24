import { SmileOutlined } from '@ant-design/icons';
import { Button, Result } from 'antd';
import React from 'react';
import { useCurrentUser } from '../../shared';

export function Home() {
  const currentUser = useCurrentUser();
  return (
    <Result
      icon={<SmileOutlined />}
      title='Hello World'
      subTitle='PRSDigg is restarting!'
      extra={
        currentUser ? (
          <span>Hello wolrd! {currentUser.name}</span>
        ) : (
          <Button type='primary' href='/login'>
            Login
          </Button>
        )
      }
    />
  );
}
