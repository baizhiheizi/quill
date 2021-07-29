import React, { Suspense } from 'react';
import { Route, Switch } from 'react-router-dom';
import LoadingComponent from './components/LoadingComponent/LoadingComponent';
const NotFoundPage = React.lazy(
  () => import('./pages/NotFoundPage/NotFoundPage'),
);
const OverviewPage = React.lazy(
  () => import('./pages/OverviewPage/OverviewPage'),
);
const ArticlePage = React.lazy(() => import('./pages/ArticlePage/ArticlePage'));
const ArticlesPage = React.lazy(
  () => import('./pages/ArticlesPage/ArticlesPage'),
);
const RevenuePage = React.lazy(() => import('./pages/RevenuePage/RevenuePage'));
const OrdersPage = React.lazy(() => import('./pages/OrdersPage/OrdersPage'));
const ArticleEditPage = React.lazy(
  () => import('./pages/ArticleEditPage/ArticleEditPage'),
);
const CommentsPage = React.lazy(
  () => import('./pages/CommentsPage/CommentsPage'),
);
const SubscriptionsPage = React.lazy(
  () => import('./pages/SubscriptionsPage/SubscriptionsPage'),
);
const NotificationsPage = React.lazy(
  () => import('./pages/NotificationsPage/NotificationsPage'),
);
const SettingsPage = React.lazy(
  () => import('./pages/SettingsPage/SettingsPage'),
);

export default function Routes() {
  return (
    <React.Fragment>
      <Suspense fallback={<LoadingComponent />}>
        <Switch>
          <Route path='/' exact>
            <OverviewPage />
          </Route>
          <Route path='/articles' exact>
            <ArticlesPage />
          </Route>
          <Route path='/articles/:uuid' exact>
            <ArticlePage />
          </Route>
          <Route path='/articles/:uuid/edit' exact>
            <ArticleEditPage />
          </Route>
          <Route path='/subscriptions' exact>
            <SubscriptionsPage />
          </Route>
          <Route path='/revenue' exact>
            <RevenuePage />
          </Route>
          <Route path='/orders' exact>
            <OrdersPage />
          </Route>
          <Route path='/comments' exact>
            <CommentsPage />
          </Route>
          <Route path='/notifications' exact>
            <NotificationsPage />
          </Route>
          <Route path='/settings' exact>
            <SettingsPage />
          </Route>
          <Route>
            <NotFoundPage />
          </Route>
        </Switch>
      </Suspense>
    </React.Fragment>
  );
}
