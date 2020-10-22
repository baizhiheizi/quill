import { SmileOutlined } from '@ant-design/icons';
import { Button, Result } from 'antd';
import React from 'react';

export function Home() {
  return (
    <Result
      icon={<SmileOutlined />}
      title='Hello World'
      subTitle='PRSDigg is restarting!'
      extra={
        <Button type='primary' href={`https://github.com/baizhiheizi/prsdigg`} target='_blank'>
          check progress
        </Button>
      }
    />
  );
}
