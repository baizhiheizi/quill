import { ApolloProvider } from '@apollo/client';
import { User } from '@graphql';
import {
  apolloClient,
  CurrentUserContext,
  hideLoader,
  mixinUtils,
  PrsdiggContext,
  UserAgentContext,
} from '@shared';
import { Col, Layout, Row } from 'antd';
import isMobile from 'ismobilejs';
import React, { Suspense, useEffect } from 'react';
import { BrowserRouter as Router } from 'react-router-dom';
import './App.less';
import LoadingComponent from './components/LoadingComponent/LoadingComponent';
import './i18n';
import Menus from './Menus';
import Routes from './Routes';

export default function App(props: {
  csrfToken: string;
  currentUser?: Partial<User>;
  prsdigg: {
    appId: string;
  };
}) {
  const { csrfToken, currentUser, prsdigg } = props;

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
              <Router>
                <Layout>
                  <Menus />
                  <Layout.Content
                    style={{ background: '#fff', padding: '1rem' }}
                  >
                    <Row justify='center'>
                      <Col
                        flex={1}
                        xs={24}
                        sm={24}
                        md={18}
                        lg={16}
                        xl={14}
                        xxl={12}
                      >
                        <Routes />
                      </Col>
                    </Row>
                  </Layout.Content>
                </Layout>
              </Router>
            </CurrentUserContext.Provider>
          </UserAgentContext.Provider>
        </PrsdiggContext.Provider>
      </ApolloProvider>
    </Suspense>
  );
}
