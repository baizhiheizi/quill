import { Avatar, Button, Divider, List, Popconfirm, Space } from 'antd';
import ListComponent from 'apps/dashboard/components/ListComponent/ListComponent';
import LoadingComponent from 'apps/dashboard/components/LoadingComponent/LoadingComponent';
import {
  useMyReadingSubscriptionConnectionQuery,
  User,
  useToggleReadingSubscribeUserActionMutation,
} from 'graphqlTypes';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function MyReadingSubscriptionsComponent() {
  const { t } = useTranslation();
  const { loading, data, fetchMore, refetch } =
    useMyReadingSubscriptionConnectionQuery();

  const [toggleReadingSubscribeUserAction] =
    useToggleReadingSubscribeUserActionMutation({
      update() {
        refetch();
      },
    });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    myReadingSubscriptionConnection: {
      nodes: readingSubscriptions,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  return (
    <ListComponent
      loading={loading}
      hasNextPage={hasNextPage}
      fetchMore={() => fetchMore({ variables: { after: endCursor } })}
      dataSource={readingSubscriptions}
      renderItem={(user: Partial<User>) => (
        <List.Item
          key={user.id}
          actions={[
            <Popconfirm
              title={t('confirm_to_unsubscribe')}
              onConfirm={() =>
                toggleReadingSubscribeUserAction({
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
                {`${t('user.bought_articles_count')}: ${
                  user.statistics.boughtArticlesCount
                }`}
                {`${t(
                  'user.reader_revenue_total',
                )}: ${user.statistics.readerRevenueTotalUsd.toFixed(2)}`}
              </Space>
            }
          />
        </List.Item>
      )}
    />
  );
}
