import { useCurrentUser } from '@shared';
import { Avatar, Col, Row, Statistic, Tabs } from 'antd';
import React from 'react';
import { useTranslation } from 'react-i18next';
import MyArticlesComponent from './components/MyArticlesComponent';
import MyCommentsComponent from './components/MyCommentsComponent';
import MyPaymentsComponent from './components/MyPaymentsComponent';
import MyTransfersComponent from './components/MyTranfersComponent';

export default function MinePage() {
  const currentUser = useCurrentUser();
  const { t } = useTranslation();
  if (!currentUser) {
    location.replace('/');
  }

  return (
    <div>
      <Row justify='center' style={{ marginBottom: '1rem' }}>
        <Col>
          <Avatar size='large' src={currentUser.avatarUrl} />
        </Col>
      </Row>
      <Row justify='center'>
        <Col>{currentUser.name}</Col>
      </Row>
      <Row gutter={16} style={{ textAlign: 'center' }}>
        <Col xs={12} sm={6}>
          <Statistic
            title={t('user.authorRevenueAmount')}
            value={currentUser.authorRevenueAmount}
          />
        </Col>
        <Col xs={12} sm={6}>
          <Statistic
            title={t('user.readerRevenueAmount')}
            value={currentUser.readerRevenueAmount}
          />
        </Col>
      </Row>
      <Tabs defaultActiveKey='author'>
        <Tabs.TabPane tab={t('minePage.tabs.author')} key='author'>
          <MyArticlesComponent type='author' />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('minePage.tabs.reader')} key='reader'>
          <MyArticlesComponent type='reader' />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('minePage.tabs.comments')} key='comments'>
          <MyCommentsComponent />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('minePage.tabs.payments')} key='payments'>
          <MyPaymentsComponent />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('minePage.tabs.transfers')} key='transfers'>
          <MyTransfersComponent />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
