import { Avatar, Button, List, Popconfirm } from 'antd';
import ListComponent from 'apps/dashboard/components/ListComponent/ListComponent';
import LoadingComponent from 'apps/dashboard/components/LoadingComponent/LoadingComponent';
import {
  useMySubscriberConnectionQuery,
  User,
  useToggleSubscribeUserActionMutation,
} from 'graphqlTypes';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function MySubscribersComponent() {
  const { t } = useTranslation();
  const { loading, data, fetchMore, refetch } = useMySubscriberConnectionQuery({
    fetchPolicy: 'cache-and-network',
  });
  const [toggleSubscribeUserAction] = useToggleSubscribeUserActionMutation({
    update() {
      refetch();
    },
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    mySubscriberConnection: {
      nodes: subscribers,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  return (
    <ListComponent
      loading={loading}
      hasNextPage={hasNextPage}
      fetchMore={() => fetchMore({ variables: { after: endCursor } })}
      dataSource={subscribers}
      renderItem={(user: Partial<User>) => (
        <List.Item
          key={user.id}
          actions={[
            <Popconfirm
              title={t('confirm_to_subscribe')}
              disabled={user.subscribed}
              onConfirm={() => {
                if (user.subscribed) {
                  return;
                }
                toggleSubscribeUserAction({
                  variables: { input: { uid: user.uid } },
                });
              }}
            >
              <Button size='small' disabled={user.subscribed}>
                {user.subscribed ? 'subscribed' : t('subscribe')}
              </Button>
            </Popconfirm>,
          ]}
        >
          <List.Item.Meta
            title={
              <a href={`/users/${user.uid}`} target='_blank'>
                {user.name}
              </a>
            }
            avatar={<Avatar src={user.avatar}>{user.name[0]}</Avatar>}
          />
        </List.Item>
      )}
    />
  );
}
