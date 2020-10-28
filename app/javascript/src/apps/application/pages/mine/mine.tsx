import { Avatar, Col, Row, Tabs } from 'antd';
import React from 'react';
import { useCurrentUser } from '../../shared';
import { Articles } from './articles';
import { Payments } from './payments';
import { Transfers } from './tranfers';

export function Mine() {
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
          <Articles type='author' />
        </Tabs.TabPane>
        <Tabs.TabPane tab='已购' key='reader'>
          <Articles type='reader' />
        </Tabs.TabPane>
        <Tabs.TabPane tab='付款' key='payments'>
          <Payments />
        </Tabs.TabPane>
        <Tabs.TabPane tab='收益' key='transfers'>
          <Transfers />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
