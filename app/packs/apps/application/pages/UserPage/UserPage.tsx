import { Button, Col, Row, Statistic, Tabs } from 'antd';
import { encode as encode64 } from 'js-base64';
import { ShakeOutlined } from '@ant-design/icons';
import LoadingComponent from 'apps/application/components/LoadingComponent/LoadingComponent';
import { useUserQuery } from 'graphqlTypes';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { useParams } from 'react-router-dom';
import UserArticlesComponent from './components/UserArticlesComponent';
import UserCommentsComponent from './components/UserCommentsComponent';
import { imagePath, usePrsdigg, useUserAgent } from 'apps/shared';

export default function UserPage() {
  const { mixinId } = useParams<{ mixinId: string }>();
  const { t } = useTranslation();
  const { appId, appName, logoFile } = usePrsdigg();
  const { mixinEnv } = useUserAgent();
  const { loading, data, refetch } = useUserQuery({ variables: { mixinId } });

  if (loading) {
    return <LoadingComponent />;
  }

  const { user } = data;

  return (
    <>
      <div className='mb-2 text-center'>
        <img
          className='w-10 h-10 mx-auto mb-2 rounded-full'
          src={user.avatar}
        />
        <div className='mb-2'>{user.name}</div>
        {mixinEnv && (
          <Button
            type='primary'
            shape='round'
            icon={<ShakeOutlined />}
            onClick={() =>
              location.replace(
                `mixin://send?category=app_card&data=${encodeURIComponent(
                  encode64(
                    JSON.stringify({
                      action: location.href,
                      app_id: appId,
                      description: `${appName} ${t('author')}`,
                      icon_url: `${imagePath(logoFile || 'logo.png')}`,
                      title: user.name,
                    }),
                  ),
                )}`,
              )
            }
          >
            {t('share')}
          </Button>
        )}
      </div>
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
        <Col xs={12} sm={6}>
          <Statistic
            title={t('user.articles_count')}
            value={user.statistics.articlesCount}
          />
        </Col>
        <Col xs={12} sm={6}>
          <Statistic
            title={t('user.bought_articles_count')}
            value={user.statistics.boughtArticlesCount}
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
    </>
  );
}
