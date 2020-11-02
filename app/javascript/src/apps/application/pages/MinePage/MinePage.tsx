import { Avatar, Col, Row, Tabs } from 'antd';
import React from 'react';
import { useCurrentUser } from '../../shared';
import ArticlesComponent from './components/ArticlesComponent';
import PaymentsComponent from './components/PaymentsComponent';
import TransfersComponent from './components/TranfersComponent';

export default function MinePage() {
  const currentUser = useCurrentUser();
  if (!currentUser) {
    location.replace('/');
  }

  return (
    <div>
      <Row justify='center'>
        <Col>
          <Avatar size='large' src={currentUser.avatarUrl} />
        </Col>
      </Row>
      <Row justify='center'>
        <Col>{currentUser.name}</Col>
      </Row>
      <Tabs defaultActiveKey='author'>
        <Tabs.TabPane tab='已发表' key='author'>
          <ArticlesComponent type='author' />
        </Tabs.TabPane>
        <Tabs.TabPane tab='已购' key='reader'>
          <ArticlesComponent type='reader' />
        </Tabs.TabPane>
        <Tabs.TabPane tab='付款' key='payments'>
          <PaymentsComponent />
        </Tabs.TabPane>
        <Tabs.TabPane tab='收益' key='transfers'>
          <TransfersComponent />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
