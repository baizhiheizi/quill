import React from 'react';
import { apolloClient } from '@shared';
import { ApolloProvider } from '@apollo/client';
import { Login } from './pages';

export default function App(props: { csrfToken: string }) {
  const { csrfToken } = props;
  return (
    <ApolloProvider client={apolloClient('/graphql', csrfToken)}>
      <div>
        <Login />
      </div>
    </ApolloProvider>
  );
}
