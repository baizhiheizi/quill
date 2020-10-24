import { ApolloProvider } from '@apollo/client';
import { User } from '@graphql';
import { apolloClient, mixinUtils } from '@shared';
import React from 'react';
import { BrowserRouter as Router } from 'react-router-dom';
import { Routes } from './routes';
import { CurrentUserContext, MixinContext } from './shared';

export default function App(props: {
  csrfToken: string;
  currentUser?: Partial<User>;
}) {
  const { csrfToken, currentUser } = props;
  return (
    <ApolloProvider client={apolloClient('/graphql', csrfToken)}>
      <MixinContext.Provider
        value={{
          mixinAppversion: mixinUtils.appVersion(),
          mixinConversationId: mixinUtils.conversationId(),
          mixinEnv: mixinUtils.environment(),
          mixinImmersive: mixinUtils.immersive(),
        }}
      >
        <CurrentUserContext.Provider value={currentUser}>
          <Router>
            <Routes />
          </Router>
        </CurrentUserContext.Provider>
      </MixinContext.Provider>
    </ApolloProvider>
  );
}
