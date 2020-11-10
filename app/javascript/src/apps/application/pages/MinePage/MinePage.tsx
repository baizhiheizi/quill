import { Avatar, Col, Row, Statistic, Tabs } from 'antd';
import React from 'react';
import { useCurrentUser } from '../../shared';
import MyArticlesComponent from './components/MyArticlesComponent';
import MyCommentsComponent from './components/MyCommentsComponent';
import MyPaymentsComponent from './components/MyPaymentsComponent';
import MyTransfersComponent from './components/MyTranfersComponent';

export default function MinePage() {
  const currentUser = useCurrentUser();
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
            title='作者收益(PRS)'
            value={currentUser.authorRevenueAmount}
          />
        </Col>
        <Col xs={12} sm={6}>
          <Statistic
            title='读者收益(PRS)'
            value={currentUser.readerRevenueAmount}
          />
        </Col>
      </Row>
      <Tabs defaultActiveKey='author'>
        <Tabs.TabPane tab='已发表' key='author'>
          <MyArticlesComponent type='author' />
        </Tabs.TabPane>
        <Tabs.TabPane tab='已购买' key='reader'>
          <MyArticlesComponent type='reader' />
        </Tabs.TabPane>
        <Tabs.TabPane tab='已评论' key='comments'>
          <MyCommentsComponent />
        </Tabs.TabPane>
        <Tabs.TabPane tab='付款记录' key='payments'>
          <MyPaymentsComponent />
        </Tabs.TabPane>
        <Tabs.TabPane tab='收益记录' key='transfers'>
          <MyTransfersComponent />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
