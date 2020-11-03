import { Button, Result } from 'antd';
import React from 'react';
import { Link, Route, Switch } from 'react-router-dom';
import ArticlesPage from './pages/ArticlesPage/ArticlesPage';
import CommentsPage from './pages/CommentsPage/CommentsPage';
import DashboardPage from './pages/DashboardPage/DashboardPage';
import PaymentsPage from './pages/Payments/PaymentsPage';
import TransfersPage from './pages/Transfers/TransfersPage';
import UsersPage from './pages/UsersPage/UsersPage';

export default function Routes() {
  return (
    <Switch>
      <Route path='/' exact>
        <DashboardPage />
      </Route>
      <Route path='/users' exact>
        <UsersPage />
      </Route>
      <Route path='/articles' exact>
        <ArticlesPage />
      </Route>
      <Route path='/comments' exact>
        <CommentsPage />
      </Route>
      <Route path='/payments' exact>
        <PaymentsPage />
      </Route>
      <Route path='/transfers' exact>
        <TransfersPage />
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
