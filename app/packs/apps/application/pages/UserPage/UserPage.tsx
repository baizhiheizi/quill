import { Avatar, Col, Row, Statistic, Tabs } from 'antd';
import LoadingComponent from 'apps/application/components/LoadingComponent/LoadingComponent';
import { useUserQuery } from 'graphqlTypes';
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
          <Avatar size='large' src={user.avatar} />
        </Col>
      </Row>
      <Row justify='center'>
        <Col>{user.name}</Col>
      </Row>
      <Row gutter={16} style={{ textAlign: 'center' }}>
        <Col xs={12} sm={6}>
          <Statistic
            title={t('user.author_revenue_total')}
            value={user.statistics.authorRevenueTotalUsd.toFixed(2)}
          />
        </Col>
        <Col xs={12} sm={6}>
          <Statistic
            title={t('user.reader_revenue_total')}
            value={user.statistics.readerRevenueTotalUsd.toFixed(2)}
          />
        </Col>
      </Row>
      <Tabs defaultActiveKey='author'>
        <Tabs.TabPane tab={t('published')} key='author'>
          <UserArticlesComponent
            mixinId={user.mixinId}
            authoringSubscribed={user.authoringSubscribed}
            refetchUser={refetch}
            type='author'
          />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('bought')} key='reader'>
          <UserArticlesComponent
            mixinId={user.mixinId}
            readingSubscribed={user.readingSubscribed}
            refetchUser={refetch}
            type='reader'
          />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('commented')} key='comments'>
          <UserCommentsComponent authorMixinId={user.mixinId} />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
