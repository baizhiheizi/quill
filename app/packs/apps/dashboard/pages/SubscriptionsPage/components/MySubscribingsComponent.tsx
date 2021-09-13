import { Avatar, Button, List, Popconfirm } from 'antd';
import ListComponent from 'apps/dashboard/components/ListComponent/ListComponent';
import LoadingComponent from 'apps/dashboard/components/LoadingComponent/LoadingComponent';
import {
  useMySubscribingConnectionQuery,
  User,
  useToggleSubscribeUserActionMutation,
} from 'graphqlTypes';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function MySubscribingsComponent() {
  const { t } = useTranslation();
  const { loading, data, fetchMore, refetch } = useMySubscribingConnectionQuery(
    { fetchPolicy: 'cache-and-network' },
  );

  const [toggleSubscribeUserAction] = useToggleSubscribeUserActionMutation({
    update() {
      refetch();
    },
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    mySubscribingConnection: {
      nodes: subscribings,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  return (
    <ListComponent
      loading={loading}
      hasNextPage={hasNextPage}
      fetchMore={() => fetchMore({ variables: { after: endCursor } })}
      dataSource={subscribings}
      renderItem={(user: Partial<User>) => (
        <List.Item
          key={user.id}
          actions={[
            <Popconfirm
              title={t('confirm_to_unsubscribe')}
              onConfirm={() =>
                toggleSubscribeUserAction({
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
          />
        </List.Item>
      )}
    />
  );
}
