import { Col, Layout, Row } from 'antd';
import { AppWrapperComponent } from 'apps/shared';
import { i18nCall } from 'apps/shared/locales/i18n';
// https://github.com/apollographql/apollo-client/issues/6381
import 'core-js/features/promise';
import { User } from 'graphqlTypes';
import isMobile from 'ismobilejs';
import React from 'react';
import { BrowserRouter as Router } from 'react-router-dom';
import HeaderComponent from './components/HeaderComponent/HeaderComponent';
import Routes from './Routes';

export default function App(props: {
  csrfToken: string;
  currentUser: Partial<User>;
  prsdigg: { appId: string; pageTitle?: string; attachmentEndpoint?: string };
  defaultLocale: 'en' | 'ja' | 'zh-CN';
  availableLocales: [string];
}) {
  i18nCall(props.availableLocales);

  return (
    <AppWrapperComponent {...props}>
      <Router basename='/dashboard'>
        <Layout style={{ minHeight: '100vh' }}>
          <HeaderComponent />
          <Layout.Content
            style={
              isMobile().phone
                ? { background: '#fff' }
                : { marginLeft: 200, padding: '1rem' }
            }
          >
            <Row justify='center'>
              <Col flex={1} xs={24} sm={24} md={24} lg={20} xl={20} xxl={14}>
                <div style={{ background: '#fff', padding: '1rem' }}>
                  <Routes />
                </div>
              </Col>
            </Row>
          </Layout.Content>
        </Layout>
      </Router>
    </AppWrapperComponent>
  );
}
