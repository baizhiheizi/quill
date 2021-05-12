import { Button, Divider, List, Popconfirm, Space } from 'antd';
import ListComponent from 'apps/dashboard/components/ListComponent/ListComponent';
import LoadingComponent from 'apps/dashboard/components/LoadingComponent/LoadingComponent';
import {
  Article,
  useMyCommentingSubscriptionConnectionQuery,
  useToggleCommentingSubscribeArticleActionMutation,
} from 'graphqlTypes';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function MyCommentingSubscriptionsComponent() {
  const { t } = useTranslation();
  const { loading, data, fetchMore, refetch } =
    useMyCommentingSubscriptionConnectionQuery();

  const [toggleCommentingSubscribeArticleAction] =
    useToggleCommentingSubscribeArticleActionMutation({
      update() {
        refetch();
      },
    });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    myCommentingSubscriptionConnection: {
      nodes: commentingSubscriptions,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  return (
    <ListComponent
      loading={loading}
      hasNextPage={hasNextPage}
      fetchMore={() => fetchMore({ variables: { after: endCursor } })}
      dataSource={commentingSubscriptions}
      renderItem={(article: Partial<Article>) => (
        <List.Item
          key={article.uuid}
          actions={[
            <Popconfirm
              title={t('confirm_to_unsubscribe')}
              onConfirm={() =>
                toggleCommentingSubscribeArticleAction({
                  variables: { input: { uuid: article.uuid } },
                })
              }
            >
              <Button size='small'>{t('unsubscribe')}</Button>
            </Popconfirm>,
          ]}
        >
          <List.Item.Meta
            title={
              <a href={`/articles/${article.uuid}`} target='_blank'>
                {article.title}
              </a>
            }
            description={
              <Space split={<Divider type='vertical' />}>
                {`${t('article.comments_count')}: ${article.commentsCount}`}
              </Space>
            }
          />
        </List.Item>
      )}
    />
  );
}
