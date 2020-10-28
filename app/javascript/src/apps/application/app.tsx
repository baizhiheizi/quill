import { ApolloProvider } from '@apollo/client';
import { User } from '@graphql';
import { apolloClient, mixinUtils } from '@shared';
import { Avatar, Button, Col, Dropdown, Layout, Menu, Row } from 'antd';
import React from 'react';
import { BrowserRouter as Router, Link } from 'react-router-dom';
import { Routes } from './routes';
import { CurrentUserContext, MixinContext, PrsdiggContext } from './shared';

export default function App(props: {
  csrfToken: string;
  currentUser?: Partial<User>;
  prsdigg: {
    appId: string;
  };
}) {
  const { csrfToken, currentUser, prsdigg } = props;
  return (
    <ApolloProvider client={apolloClient('/graphql', csrfToken)}>
      <PrsdiggContext.Provider value={prsdigg}>
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
                  <Row justify='center' style={{flexWrap: 'nowrap'}}>
                    <Col>
                      <h1 style={{ padding: '0 1rem', textAlign: 'center' }}>
                        LOGO
                      </h1>
                    </Col>
                    <Col flex={1}>
                      <Menu theme='light' mode='horizontal' selectable={false}>
                        <Menu.Item>
                          <Link to='/' replace>
                            读文章
                          </Link>
                        </Menu.Item>
                        <Menu.Item>
                          {currentUser ? (
                            <Link to='/articles/new' replace>
                              写文章
                            </Link>
                          ) : (
                            <a href={`/login?redirect_uri=${location.href}`}>
                              New
                            </a>
                          )}
                        </Menu.Item>
                        <Menu.Item>
                          <Link to='/rules'>规则</Link>
                        </Menu.Item>
                      </Menu>
                    </Col>
                    <Col>
                      {currentUser ? (
                        <Dropdown
                          placement='bottomLeft'
                          trigger={['click']}
                          overlay={
                            <Menu selectable={false}>
                              <Menu.Item>
                                <Link to='/mine'>
                                  <a>个人中心</a>
                                </Link>
                              </Menu.Item>
                              <Menu.Item>
                                <a href='/logout'>登出</a>
                              </Menu.Item>
                            </Menu>
                          }
                        >
                          <div style={{ padding: '0 1rem' }}>
                            <Avatar src={currentUser.avatarUrl}>
                              {currentUser.name[0]}
                            </Avatar>
                          </div>
                        </Dropdown>
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
                  <Row justify='center'>
                    <Col flex={1} xs={24} sm={24} md={18} lg={16} xl={14} xxl={12}>
                      <Routes />
                    </Col>
                  </Row>
                </Layout.Content>
              </Layout>
            </Router>
          </CurrentUserContext.Provider>
        </MixinContext.Provider>
      </PrsdiggContext.Provider>
    </ApolloProvider>
  );
}
