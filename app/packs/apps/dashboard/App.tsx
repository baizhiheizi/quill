import { ApolloProvider } from '@apollo/client';
import { Col, Layout, message, Row } from 'antd';
import {
  apolloClient,
  CurrentUserContext,
  hideLoader,
  mixinContext,
  PrsdiggContext,
  UserAgentContext,
} from 'apps/shared';
import 'apps/shared/locales/i18n';
import consumer from 'channels/consumer';
// https://github.com/apollographql/apollo-client/issues/6381
import 'core-js/features/promise';
import { User } from 'graphqlTypes';
import isMobile from 'ismobilejs';
import React, { Suspense, useEffect, useState } from 'react';
import { BrowserRouter as Router } from 'react-router-dom';
import LoadingComponent from './components/LoadingComponent/LoadingComponent';
import Menus from './Menus';
import Routes from './Routes';

export default function App(props: {
  csrfToken: string;
  currentUser: Partial<User>;
  prsdigg: { appId: String };
}) {
  const { csrfToken, prsdigg } = props;
  const [currentUser, setCurrentUser] = useState(props.currentUser);
  if (!Boolean(currentUser)) {
    location.replace('/');
  }

  useEffect(() => {
    hideLoader();
  }, []);

  useEffect(() => {
    if (!currentUser) {
      return;
    }
    consumer.subscriptions.create('Noticed::NotificationChannel', {
      connected() {
        console.log('Action Cable Connected');
      },
      disconnected() {
        console.log('Action Cable disconnected');
      },
      received(data: any) {
        message.info(data);
      },
    });
  }, [currentUser]);

  return (
    <Suspense fallback={<LoadingComponent />}>
      <ApolloProvider client={apolloClient('/graphql', csrfToken)}>
        <PrsdiggContext.Provider value={prsdigg}>
          <UserAgentContext.Provider
            value={{
              mixinAppearance: mixinContext.appearance,
              mixinCurrency: mixinContext.currency,
              mixinAppversion: mixinContext.appVersion,
              mixinConversationId: mixinContext.conversationId,
              mixinEnv: mixinContext.platform,
              mixinImmersive: mixinContext.immersive,
              isMobile: isMobile(),
            }}
          >
            <CurrentUserContext.Provider
              value={{ currentUser, setCurrentUser }}
            >
              <Router basename='/dashboard'>
                <Layout style={{ minHeight: '100vh' }}>
                  <Menus />
                  <Layout.Content
                    style={
                      isMobile().phone
                        ? { background: '#fff' }
                        : { marginLeft: 200, padding: '1rem' }
                    }
                  >
                    <Row justify='center'>
                      <Col
                        flex={1}
                        xs={24}
                        sm={24}
                        md={24}
                        lg={20}
                        xl={20}
                        xxl={14}
                      >
                        <div style={{ background: '#fff', padding: '1rem' }}>
                          <Routes />
                        </div>
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
