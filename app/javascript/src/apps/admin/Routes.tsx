import { Button, Result } from 'antd';
import React from 'react';
import { Link, Route, Switch } from 'react-router-dom';
import AnnouncementsPage from './pages/AnnouncementsPage/AnnouncementsPage';
import ArticlePage from './pages/ArticlePage/ArticlePage';
import ArticlesPage from './pages/ArticlesPage/ArticlesPage';
import BalancePage from './pages/BalancePage/BalancePage';
import BonusesPage from './pages/BonusesPage/BonusesPage';
import CommentsPage from './pages/CommentsPage/CommentsPage';
import MixinMessagesPage from './pages/MixinMessagesPage/MixinMessagesPage';
import MixinNetworkSnapshotsPage from './pages/MixinNetworkSnapshotsPage/MixinNetworkSnapshotsPage';
import OverviewPage from './pages/OverviewPage/OverviewPage';
import PaymentsPage from './pages/PaymentsPage/PaymentsPage';
import SwapOrdersPage from './pages/SwapOrdersPage/SwapOrdersPage';
import TransfersPage from './pages/TransfersPage/TransfersPage';
import UsersPage from './pages/UsersPage/UsersPage';

export default function Routes() {
  return (
    <Switch>
      <Route path='/' exact>
        <OverviewPage />
      </Route>
      <Route path='/users' exact>
        <UsersPage />
      </Route>
      <Route path='/articles' exact>
        <ArticlesPage />
      </Route>
      <Route path='/articles/:uuid' exact>
        <ArticlePage />
      </Route>
      <Route path='/comments' exact>
        <CommentsPage />
      </Route>
      <Route path='/payments' exact>
        <PaymentsPage />
      </Route>
      <Route path='/swap_orders' exact>
        <SwapOrdersPage />
      </Route>
      <Route path='/transfers' exact>
        <TransfersPage />
      </Route>
      <Route path='/mixin_messages' exact>
        <MixinMessagesPage />
      </Route>
      <Route path='/mixin_network_snapshots' exact>
        <MixinNetworkSnapshotsPage />
      </Route>
      <Route path='/announcements' exact>
        <AnnouncementsPage />
      </Route>
      <Route path='/bonuses' exact>
        <BonusesPage />
      </Route>
      <Route path='/balance' exact>
        <BalancePage />
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
