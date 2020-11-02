import React from 'react';
import { apolloClient } from '@shared';
import { ApolloProvider } from '@apollo/client';
import LoginPage from './pages/LoginPage/LoginPage';

export default function App(props: { csrfToken: string }) {
  const { csrfToken } = props;
  return (
    <ApolloProvider client={apolloClient('/graphql', csrfToken)}>
      <div>
        <LoginPage />
      </div>
    </ApolloProvider>
  );
}
