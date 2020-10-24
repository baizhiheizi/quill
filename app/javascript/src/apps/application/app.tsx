import React from 'react';
import { apolloClient } from '@shared';
import { ApolloProvider } from '@apollo/client';
import { Home } from './pages';
import { CurrentUserContext } from './shared';

interface UserType {
  avatarUrl?: string;
  name?: string;
  mixinId?: string;
  mixinUuid?: string;
}

export default function App(props: {
  csrfToken: string;
  currentUser?: UserType;
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
