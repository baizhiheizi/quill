import LoadingComponent from '@dashboard/components/LoadingComponent/LoadingComponent';
import { updateActiveMenu } from '@dashboard/shared';
import {
  Notification as INotification,
  useClearNotificationsMutation,
  useMyNotificationConnectionQuery,
  useReadNotificationMutation,
  useReadNotificationsMutation,
} from '@graphql';
import { Button, List, PageHeader } from 'antd';
import React from 'react';
import { useTranslation } from 'react-i18next';
import ListComponent from '../../components/ListComponent/ListComponent';

export default function NotificationsPage() {
  updateActiveMenu('notifications');
  const { t } = useTranslation();
  const {
    loading,
    data,
    fetchMore,
    refetch,
  } = useMyNotificationConnectionQuery();
  const [readNotification] = useReadNotificationMutation();
  const [readNotifications] = useReadNotificationsMutation({
    variables: { input: {} },
    update() {
      refetch();
    },
  });
  const [clearNotifications] = useClearNotificationsMutation({
    variables: { input: {} },
    update() {
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
        title={t('dashboard.menu.notifications')}
        extra={[
          <Button
            key='clearAll'
            type='default'
            onClick={() => clearNotifications()}
          >
            {t('dashboard.notificationsPage.clearAllBtn')}
          </Button>,
          <Button
            key='readAll'
            type='primary'
            onClick={() => readNotifications()}
          >
            {t('dashboard.notificationsPage.readAllBtn')}
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
          </List.Item>
        )}
      />
    </div>
  );
}
