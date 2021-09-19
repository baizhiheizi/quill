import { Avatar, Button, List, Popconfirm } from 'antd';
import LoadingComponent from 'apps/application/components/LoadingComponent/LoadingComponent';
import LoadMoreComponent from 'apps/application/components/LoadMoreComponent/LoadMoreComponent';
import { useCurrentUser } from 'apps/shared';
import {
  User,
  useToggleSubscribeUserActionMutation,
  useUserSubscriberConnectionQuery,
} from 'graphqlTypes';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';

export default function UserSubscribersComponent(props: { uid: string }) {
  const { uid } = props;
  const { t, i18n } = useTranslation();
  const { currentUser } = useCurrentUser();
  moment.locale(i18n.language);
  const { data, loading, fetchMore } = useUserSubscriberConnectionQuery({
    variables: { uid },
  });
  const [toggleSubscribeUserAction] = useToggleSubscribeUserActionMutation();

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    userSubscriberConnection: {
      nodes: users,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  return (
    <List
      size='small'
      itemLayout='horizontal'
      dataSource={users}
      loadMore={
        <LoadMoreComponent
          hasNextPage={hasNextPage}
          loading={loading}
          fetchMore={() => {
            fetchMore({
              variables: {
                after: endCursor,
              },
            });
          }}
        />
      }
      renderItem={(user: Partial<User>) => (
        <List.Item
          key={user.uid}
          actions={[
            <>
              {currentUser.uid !== user.uid && (
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
                    {user.subscribed ? t('subscribed') : t('subscribe')}
                  </Button>
                </Popconfirm>
              )}
            </>,
          ]}
        >
          <List.Item.Meta
            title={<Link to={`/users/${user.uid}`}>{user.name}</Link>}
            avatar={<Avatar src={user.avatar}>{user.name[0]}</Avatar>}
          />
        </List.Item>
      )}
    />
  );
}
