import ListComponent from '@dashboard/components/ListComponent/ListComponent';
import LoadingComponent from '@dashboard/components/LoadingComponent/LoadingComponent';
import {
  Tag as ITag,
  useMyTagSubscriptionConnectionQuery,
  useToggleSubscribeTagActionMutation,
} from '@graphql';
import { Button, Divider, List, Popconfirm, Space, Tag } from 'antd';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function MyTagSubscriptionsComponent() {
  const { t } = useTranslation();
  const {
    loading,
    data,
    fetchMore,
    refetch,
  } = useMyTagSubscriptionConnectionQuery();

  const [toggleTagSubscribeUserAction] = useToggleSubscribeTagActionMutation({
    update() {
      refetch();
    },
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    myTagSubscriptionConnection: {
      nodes: tagSubscriptions,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  return (
    <ListComponent
      loading={loading}
      hasNextPage={hasNextPage}
      fetchMore={() => fetchMore({ variables: { after: endCursor } })}
      dataSource={tagSubscriptions}
      renderItem={(tag: Partial<ITag>) => (
        <List.Item
          key={tag.id}
          actions={[
            <Popconfirm
              title={t('dashboard.subscriptionsPage.confirmToUnsubscribe')}
              onConfirm={() =>
                toggleTagSubscribeUserAction({
                  variables: { input: { mixinId: tag.id } },
                })
              }
            >
              <Button size='small'>{t('common.unsubscribeBtn')}</Button>
            </Popconfirm>,
          ]}
        >
          <List.Item.Meta
            title={
              <div>
                <a href={`/tags/${tag.id}`} target='_blank'>
                  <Tag color={tag.color}>#{tag.name}</Tag>
                </a>
              </div>
            }
            description={
              <Space split={<Divider type='vertical' />} wrap>
                {`${t('tag.articlesCount')}: ${tag.articlesCount}`}
                {`${t('tag.subscribersCount')}: ${tag.subscribersCount}`}
              </Space>
            }
          />
        </List.Item>
      )}
    />
  );
}
