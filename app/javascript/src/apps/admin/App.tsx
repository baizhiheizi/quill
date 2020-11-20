import { ApolloProvider } from '@apollo/client';
import { apolloClient } from '@shared';
import { Layout } from 'antd';
import React from 'react';
import { BrowserRouter as Router } from 'react-router-dom';
import Menus from './Menus';
import LoginPage from './pages/LoginPage/LoginPage';
import Routes from './Routes';
import { CurrentAdminContext, PrsdiggContext } from './shared';

export default function App(props: {
  csrfToken: string;
  currentAdmin?: { name: String };
  prsdigg: { appId: String };
}) {
  const { csrfToken, currentAdmin, prsdigg } = props;
  return (
    <ApolloProvider client={apolloClient('/graphql', csrfToken)}>
      {currentAdmin ? (
        <PrsdiggContext.Provider value={prsdigg}>
          <CurrentAdminContext.Provider value={currentAdmin}>
            <Router basename='/admin'>
              <Layout style={{ minHeight: '100vh' }}>
                <Layout.Sider collapsible>
                  <Menus />
                </Layout.Sider>
                <Layout.Content
                  style={{ padding: '0 1rem', background: '#fff' }}
                >
                  <Routes />
                </Layout.Content>
              </Layout>
            </Router>
          </CurrentAdminContext.Provider>
        </PrsdiggContext.Provider>
      ) : (
        <LoginPage />
      )}
    </ApolloProvider>
  );
}
