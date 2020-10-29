import React from 'react';
import { Route, Switch } from 'react-router-dom';
import { Article, ArticleNew, Fair, Home, Mine, Rules } from './pages';

export function Routes() {
  return (
    <React.Fragment>
      <Route path='/' exact>
        <Home />
      </Route>
      <Switch>
        <Route path='/articles/new' exact>
          <ArticleNew />
        </Route>
        <Route path='/articles/:uuid' exact>
          <Article />
        </Route>
      </Switch>
      <Route path='/rules' exact>
        <Rules />
      </Route>
      <Route path='/mine' exact>
        <Mine />
      </Route>
      <Route path='/fair' exact>
        <Fair />
      </Route>
    </React.Fragment>
  );
}
