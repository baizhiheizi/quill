import { ApolloProvider } from '@apollo/client';
import { User } from '@graphql';
import {
  ActiveMenuContext,
  apolloClient,
  CurrentUserContext,
  hideLoader,
  mixinUtils,
  PrsdiggContext,
  UserAgentContext,
} from '@shared';
import { Layout } from 'antd';
import isMobile from 'ismobilejs';
import React, { Suspense, useEffect, useState } from 'react';
import { BrowserRouter as Router } from 'react-router-dom';
import LoadingComponent from './components/LoadingComponent/LoadingComponent';
import './i18n';
import Menus from './Menus';
import Routes from './Routes';

export default function App(props: {
  csrfToken: string;
  currentUser: Partial<User>;
  prsdigg: { appId: String };
}) {
  const { csrfToken, currentUser, prsdigg } = props;
  const [activeMenu, setActiveMenu] = useState('');
  if (!Boolean(currentUser)) {
    location.replace('/');
  }

  useEffect(() => {
    hideLoader();
  }, []);

  return (
    <Suspense fallback={<LoadingComponent />}>
      <ApolloProvider client={apolloClient('/graphql', csrfToken)}>
        <PrsdiggContext.Provider value={prsdigg}>
          <UserAgentContext.Provider
            value={{
              mixinAppversion: mixinUtils.appVersion(),
              mixinConversationId: mixinUtils.conversationId(),
              mixinEnv: mixinUtils.environment(),
              mixinImmersive: mixinUtils.immersive(),
              isMobile: isMobile(),
            }}
          >
            <CurrentUserContext.Provider value={currentUser}>
              <ActiveMenuContext.Provider value={{ activeMenu, setActiveMenu }}>
                <Router basename='/dashboard'>
                  <Layout style={{ minHeight: '100vh' }}>
                    <Menus activeMenu={activeMenu} />
                    <Layout.Content
                      style={
                        isMobile().phone
                          ? { background: '#fff' }
                          : { padding: '1rem' }
                      }
                    >
                      <div style={{ background: '#fff', padding: '1rem' }}>
                        <Routes />
                      </div>
                    </Layout.Content>
                  </Layout>
                </Router>
              </ActiveMenuContext.Provider>
            </CurrentUserContext.Provider>
          </UserAgentContext.Provider>
        </PrsdiggContext.Provider>
      </ApolloProvider>
    </Suspense>
  );
}
