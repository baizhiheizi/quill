import { Result, Button } from 'antd';
import React from 'react';
import { Link } from 'react-router-dom';

export default function NotFoundPage() {
  if (location.pathname == '/widget/articles') {
    location.replace(location.href);
    return null;
  }

  return (
    <Result
      status='404'
      title='404'
      subTitle='Sorry, the page you visited does not exist.'
      extra={
        <Link to='/'>
          <Button type='primary'>Back Home</Button>
        </Link>
      }
    />
  );
}
