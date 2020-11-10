import ArticlesComponent from '@application/components/ArticlesComponent/ArticlesComponent';
import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import { useUserQuery } from '@graphql';
import { Avatar, Col, Row, Statistic, Tabs } from 'antd';
import React from 'react';
import { useParams } from 'react-router-dom';
import UserCommentsComponent from './components/UserCommentsComponent';

export default function UserPage() {
  const { mixinId } = useParams<{ mixinId: string }>();
  const { loading, data } = useUserQuery({ variables: { mixinId } });

  if (loading) {
    return <LoadingComponent />;
  }

  const { user } = data;

  return (
    <div>
      <Row justify='center' style={{ marginBottom: '1rem' }}>
        <Col>
          <Avatar size='large' src={user.avatarUrl} />
        </Col>
      </Row>
      <Row justify='center'>
        <Col>{user.name}</Col>
      </Row>
      <Row gutter={16} style={{ textAlign: 'center' }}>
        <Col xs={12} sm={6}>
          <Statistic title='作者收益(PRS)' value={user.authorRevenueAmount} />
        </Col>
        <Col xs={12} sm={6}>
          <Statistic title='读者收益(PRS)' value={user.readerRevenueAmount} />
        </Col>
      </Row>
      <Tabs defaultActiveKey='author'>
        <Tabs.TabPane tab='已发表' key='author'>
          <ArticlesComponent mixinId={user.mixinId} type='author' />
        </Tabs.TabPane>
        <Tabs.TabPane tab='已购买' key='reader'>
          <ArticlesComponent mixinId={user.mixinId} type='reader' />
        </Tabs.TabPane>
        <Tabs.TabPane tab='已评论' key='comments'>
          <UserCommentsComponent authorMixinId={user.mixinId} />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
