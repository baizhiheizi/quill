import React, { Suspense } from 'react';
import { Route, Switch } from 'react-router-dom';
import LoadingComponent from './components/LoadingComponent/LoadingComponent';
const NotFoundPage = React.lazy(
  () => import('./pages/NotFoundPage/NotFoundPage'),
);
const OverviewPage = React.lazy(
  () => import('./pages/OverviewPage/OverviewPage'),
);

export default function Routes() {
  return (
    <React.Fragment>
      <Suspense fallback={<LoadingComponent />}>
        <Switch>
          <Route path='/' exact>
            <OverviewPage />
          </Route>
          <Route>
            <NotFoundPage />
          </Route>
        </Switch>
      </Suspense>
    </React.Fragment>
  );
}
