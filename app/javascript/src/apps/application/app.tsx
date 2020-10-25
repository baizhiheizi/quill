import { ApolloProvider } from '@apollo/client';
import { User } from '@graphql';
import { apolloClient, mixinUtils } from '@shared';
import { Avatar, Button, Col, Layout, Menu, Row } from 'antd';
import React from 'react';
import { BrowserRouter as Router, useHistory } from 'react-router-dom';
import { Routes } from './routes';
import { CurrentUserContext, MixinContext } from './shared';

export default function App(props: {
  csrfToken: string;
  currentUser?: Partial<User>;
}) {
  const { csrfToken, currentUser } = props;
  const pathnames = location.pathname.split('/');
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
            <Layout>
              <Layout.Header
                style={{
                  WebkitBoxShadow: '0 2px 8px #f0f1f2',
                  background: '#fff',
                  boxShadow: '0 2px 8px #f0f1f2',
                  padding: 0,
                  zIndex: 10,
                }}
              >
                <Row gutter={16}>
                  <Col>
                    <h1 style={{ padding: '0 1rem', textAlign: 'center' }}>
                      LOGO
                    </h1>
                  </Col>
                  <Col flex={1}>
                    <Menu
                      theme='light'
                      mode='horizontal'
                      defaultSelectedKeys={[
                        pathnames[pathnames.length - 1] || 'home',
                      ]}
                    >
                      <Menu.Item key='home'>
                        <a href='/'>Home</a>
                      </Menu.Item>
                      <Menu.Item key='new'>
                        <a href='/articles/new'>New</a>
                      </Menu.Item>
                    </Menu>
                  </Col>
                  <Col>
                    {currentUser ? (
                      <div style={{ padding: '0 1rem' }}>
                        <Avatar src={currentUser.avatarUrl} />
                      </div>
                    ) : (
                      <Button type='link' href='/login'>
                        Login
                      </Button>
                    )}
                  </Col>
                </Row>
              </Layout.Header>
              <Layout.Content
                style={{ background: '#fff', padding: '2rem 1rem ' }}
              >
                <Routes />
              </Layout.Content>
            </Layout>
          </Router>
        </CurrentUserContext.Provider>
      </MixinContext.Provider>
    </ApolloProvider>
  );
}
