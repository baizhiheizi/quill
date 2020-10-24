import React from 'react';
import { Route } from 'react-router-dom';
import { Home } from './pages';

export function Routes() {
  return (
    <Route path='/' exact>
      <Home />
    </Route>
  );
}
