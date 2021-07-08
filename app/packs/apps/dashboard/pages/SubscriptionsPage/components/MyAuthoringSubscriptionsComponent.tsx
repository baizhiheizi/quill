import { Avatar, Button, Divider, List, Popconfirm, Space } from 'antd';
import ListComponent from 'apps/dashboard/components/ListComponent/ListComponent';
import LoadingComponent from 'apps/dashboard/components/LoadingComponent/LoadingComponent';
import {
  useMyAuthoringSubscriptionConnectionQuery,
  User,
  useToggleAuthoringSubscribeUserActionMutation,
} from 'graphqlTypes';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function MyAuthoringSubscriptionsComponent() {
  const { t } = useTranslation();
  const { loading, data, fetchMore, refetch } =
    useMyAuthoringSubscriptionConnectionQuery();
  const [toggleAuthoringSubscribeUserAction] =
    useToggleAuthoringSubscribeUserActionMutation({
      update() {
        refetch();
      },
    });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    myAuthoringSubscriptionConnection: {
      nodes: authoringSubscriptions,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  return (
    <ListComponent
      loading={loading}
      hasNextPage={hasNextPage}
      fetchMore={() => fetchMore({ variables: { after: endCursor } })}
      dataSource={authoringSubscriptions}
      renderItem={(user: Partial<User>) => (
        <List.Item
          key={user.id}
          actions={[
            <Popconfirm
              title={t('confirm_to_unsubscribe')}
              onConfirm={() =>
                toggleAuthoringSubscribeUserAction({
                  variables: { input: { mixinId: user.mixinId } },
                })
              }
            >
              <Button size='small'>{t('unsubscribe')}</Button>
            </Popconfirm>,
          ]}
        >
          <List.Item.Meta
            title={
              <a href={`/users/${user.mixinId}`} target='_blank'>
                {user.name}
              </a>
            }
            avatar={<Avatar src={user.avatar}>{user.name[0]}</Avatar>}
            description={
              <Space split={<Divider type='vertical' />} wrap>
                {`${t('user.articles_count')}: ${
                  user.statistics.articlesCount
                }`}
                {`${t(
                  'user.author_revenue_total',
                )}: ${user.statistics.authorRevenueTotalUsd.toFixed(2)}`}
              </Space>
            }
          />
        </List.Item>
      )}
    />
  );
}
