import React from 'react';
import { apolloClient } from '@shared';
import { ApolloProvider } from '@apollo/client';
import { Home } from './pages';

export default function App(props: { csrfToken: string }) {
  const { csrfToken } = props;
  return (
    <ApolloProvider client={apolloClient('/graphql', csrfToken)}>
      <div>
        <Home />
      </div>
    </ApolloProvider>
  );
}
