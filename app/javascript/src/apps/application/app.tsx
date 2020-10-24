import React from 'react';
import { apolloClient, mixinUtils } from '@shared';
import { ApolloProvider } from '@apollo/client';
import { Home } from './pages';
import { CurrentUserContext, MixinContext } from './shared';
import { User } from '@graphql';

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
          <div>
            <Home />
          </div>
        </CurrentUserContext.Provider>
      </MixinContext.Provider>
    </ApolloProvider>
  );
}
