import { AlertOutlined, ShakeOutlined } from '@ant-design/icons';
import { Button, Col, Row, Statistic, Tabs } from 'antd';
import LoadingComponent from 'apps/application/components/LoadingComponent/LoadingComponent';
import LoginModalComponent from 'apps/application/components/LoginModalComponent/LoginModalComponent';
import {
  imagePath,
  useCurrentUser,
  usePrsdigg,
  useUserAgent,
} from 'apps/shared';
import {
  useToggleSubscribeUserActionMutation,
  useUserQuery,
} from 'graphqlTypes';
import { encode as encode64 } from 'js-base64';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { useParams } from 'react-router-dom';
import UserArticlesComponent from './components/UserArticlesComponent';
import UserCommentsComponent from './components/UserCommentsComponent';
import UserSubscribersComponent from './components/UserSubscribersComponent';
import UserSubscribingsComponent from './components/UserSubscribingsComponent';

export default function UserPage() {
  const { uid } = useParams<{ uid: string }>();
  const { t } = useTranslation();
  const { currentUser } = useCurrentUser();
  const { appId, appName, logoFile } = usePrsdigg();
  const { mixinEnv } = useUserAgent();
  const { loading, data, refetch } = useUserQuery({ variables: { uid } });
  const [toggleSubscribeUserAction] = useToggleSubscribeUserActionMutation({
    update(_, { data: { toggleSubscribeUserAction: success } }) {
      if (success) {
        refetch();
      }
    },
  });

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
        <div className='flex items-center justify-center space-x-2'>
          {currentUser ? (
            currentUser.uid !== user.uid && (
              <Button
                type='primary'
                ghost
                danger={user?.subscribed}
                shape='round'
                icon={<AlertOutlined />}
                onClick={() =>
                  toggleSubscribeUserAction({
                    variables: { input: { uid } },
                  })
                }
              >
                {user?.subscribed ? t('unsubscribe') : t('subscribe')}
              </Button>
            )
          ) : (
            <LoginModalComponent>
              <Button
                type='primary'
                ghost
                shape='round'
                icon={<AlertOutlined />}
              >
                {t('subscribe')}
              </Button>
            </LoginModalComponent>
          )}
          {mixinEnv && (
            <Button
              type='primary'
              ghost
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
          <UserArticlesComponent uid={user.uid} type='author' />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('subscribing')} key='subscribing'>
          <UserSubscribingsComponent uid={user.uid} />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('subscribers')} key='subscribers'>
          <UserSubscribersComponent uid={user.uid} />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('bought')} key='reader'>
          <UserArticlesComponent uid={user.uid} type='reader' />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('commented')} key='comments'>
          <UserCommentsComponent uid={user.uid} />
        </Tabs.TabPane>
      </Tabs>
    </>
  );
}