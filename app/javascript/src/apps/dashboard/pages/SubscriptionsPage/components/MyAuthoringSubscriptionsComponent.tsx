import ListComponent from '@dashboard/components/ListComponent/ListComponent';
import LoadingComponent from '@dashboard/components/LoadingComponent/LoadingComponent';
import {
  useMyAuthoringSubscriptionConnectionQuery,
  User,
  useToggleAuthoringSubscribeUserActionMutation,
} from '@graphql';
import { Avatar, Button, List, Popconfirm } from 'antd';
import { useTranslation } from 'react-i18next';
import React from 'react';

export default function MyAuthoringSubscriptionsComponent() {
  const { t } = useTranslation();
  const {
    loading,
    data,
    fetchMore,
    refetch,
  } = useMyAuthoringSubscriptionConnectionQuery();
  const [
    toggleAuthoringSubscribeUserAction,
  ] = useToggleAuthoringSubscribeUserActionMutation({
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
              title={t('dashboard.subscriptionsPage.confirmToUnsubscribe')}
              onConfirm={() =>
                toggleAuthoringSubscribeUserAction({
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
