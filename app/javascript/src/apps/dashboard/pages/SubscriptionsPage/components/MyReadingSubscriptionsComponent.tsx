import ListComponent from '@dashboard/components/ListComponent/ListComponent';
import LoadingComponent from '@dashboard/components/LoadingComponent/LoadingComponent';
import {
  useMyReadingSubscriptionConnectionQuery,
  User,
  useToggleReadingSubscribeUserActionMutation,
} from '@graphql';
import { Avatar, Button, List, Popconfirm } from 'antd';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function MyReadingSubscriptionsComponent() {
  const { t } = useTranslation();
  const {
    loading,
    data,
    fetchMore,
    refetch,
  } = useMyReadingSubscriptionConnectionQuery();

  const [
    toggleReadingSubscribeUserAction,
  ] = useToggleReadingSubscribeUserActionMutation({
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
              title={t('dashboard.subscriptionsPage.confirmToUnsubscribe')}
              onConfirm={() =>
                toggleReadingSubscribeUserAction({
                  variables: { input: { mixinId: user.mixinId } },
                })
              }
            >
              <Button size='small'>{t('common.unsubscribeBtn')}</Button>
            </Popconfirm>,
          ]}
        >
          <List.Item.Meta
            title={user.name}
            avatar={<Avatar src={user.avatarUrl}>{user.name[0]}</Avatar>}
          />
        </List.Item>
      )}
    />
  );
}
