import React from 'react';
import { apolloClient } from '@shared';
import { ApolloProvider } from '@apollo/client';
import { Home } from './pages';
import { CurrentUserContext } from './shared';
import { User } from '@graphql';

export default function App(props: {
  csrfToken: string;
  currentUser?: Partial<User>;
}) {
  const { csrfToken, currentUser } = props;
  return (
    <ApolloProvider client={apolloClient('/graphql', csrfToken)}>
      <CurrentUserContext.Provider value={currentUser}>
        <div>
          <Home />
        </div>
      </CurrentUserContext.Provider>
    </ApolloProvider>
  );
}
