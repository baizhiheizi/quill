import { Button, List, PageHeader } from 'antd';
import LoadingComponent from 'apps/dashboard/components/LoadingComponent/LoadingComponent';
import { useCurrentUser } from 'apps/shared';
import {
  Notification as INotification,
  useClearNotificationsMutation,
  useMyNotificationConnectionQuery,
  useReadNotificationMutation,
  useReadNotificationsMutation,
} from 'graphqlTypes';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';
import ListComponent from '../../components/ListComponent/ListComponent';

export default function NotificationsPage() {
  const { currentUser, setCurrentUser } = useCurrentUser();
  const { t, i18n } = useTranslation();
  moment.locale(i18n.language);
  const { loading, data, fetchMore, refetch } =
    useMyNotificationConnectionQuery({ fetchPolicy: 'cache-and-network' });
  const [readNotification] = useReadNotificationMutation();
  const [readNotifications] = useReadNotificationsMutation({
    variables: { input: {} },
    update() {
      setCurrentUser({ ...currentUser, unreadNotificationsCount: 0 });
      refetch();
    },
  });
  const [clearNotifications] = useClearNotificationsMutation({
    variables: { input: {} },
    update() {
      setCurrentUser({ ...currentUser, unreadNotificationsCount: 0 });
      refetch();
    },
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    myNotificationConnection: {
      nodes: notifications,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  return (
    <div>
      <PageHeader
        title={t('notifications_manage')}
        extra={[
          <Button
            key='clearAll'
            type='default'
            onClick={() => clearNotifications()}
          >
            {t('clear_all')}
          </Button>,
          <Button
            key='readAll'
            type='primary'
            onClick={() => readNotifications()}
          >
            {t('read_all')}
          </Button>,
        ]}
      />
      <ListComponent
        loading={loading}
        hasNextPage={hasNextPage}
        fetchMore={() => fetchMore({ variables: { after: endCursor } })}
        dataSource={notifications}
        renderItem={(notification: Partial<INotification>) => (
          <List.Item
            key={notification.id}
            onClick={() =>
              readNotification({
                variables: { input: { id: notification.id } },
              })
            }
            style={{ color: `${notification.readAt ? '#aaa' : '#1890ff'}` }}
          >
            <div>
              {notification.url ? (
                <a
                  style={{ color: 'unset' }}
                  href={notification.url}
                  target='_blank'
                >
                  {notification.message}
                </a>
              ) : (
                <span>{notification.message}</span>
              )}
            </div>
            <div>
              {moment(notification.createdAt).format('YYYY-MM-DD hh:mm')}
            </div>
          </List.Item>
        )}
      />
    </div>
  );
}
