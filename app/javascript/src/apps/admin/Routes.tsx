import { Button, Result } from 'antd';
import React from 'react';
import { Link, Route, Switch } from 'react-router-dom';
import DashboardPage from './pages/DashboardPage/DashboardPage';

export default function Routes() {
  return (
    <Switch>
      <Route path='/' exact>
        <DashboardPage />
      </Route>
      <Route>
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
      </Route>
    </Switch>
  );
}
