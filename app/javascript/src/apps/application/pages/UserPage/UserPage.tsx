import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import { useUserQuery } from '@graphql';
import { Avatar, Col, Row, Statistic, Tabs } from 'antd';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { useParams } from 'react-router-dom';
import UserArticlesComponent from './components/UserArticlesComponent';
import UserCommentsComponent from './components/UserCommentsComponent';

export default function UserPage() {
  const { mixinId } = useParams<{ mixinId: string }>();
  const { t } = useTranslation();
  const { loading, data, refetch } = useUserQuery({ variables: { mixinId } });

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
          <Statistic
            title={t('user.authorRevenueAmount')}
            value={user.authorRevenueAmount}
          />
        </Col>
        <Col xs={12} sm={6}>
          <Statistic
            title={t('user.readerRevenueAmount')}
            value={user.readerRevenueAmount}
          />
        </Col>
      </Row>
      <Tabs defaultActiveKey='author'>
        <Tabs.TabPane tab={t('userPage.tabs.author')} key='author'>
          <UserArticlesComponent
            mixinId={user.mixinId}
            authoringSubscribed={user.authoringSubscribed}
            refetchUser={refetch}
            type='author'
          />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('userPage.tabs.reader')} key='reader'>
          <UserArticlesComponent
            mixinId={user.mixinId}
            readingSubscribed={user.readingSubscribed}
            refetchUser={refetch}
            type='reader'
          />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('userPage.tabs.comments')} key='comments'>
          <UserCommentsComponent authorMixinId={user.mixinId} />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
