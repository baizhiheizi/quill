import { AlertOutlined, ShareAltOutlined } from '@ant-design/icons';
import { Button, Card, Divider, List, Space, Typography } from 'antd';
import ArticleListItemComponent from 'apps/application/components/ArticleListItemComponent/ArticleListItemComponent';
import LoadingComponent from 'apps/application/components/LoadingComponent/LoadingComponent';
import LoadMoreComponent from 'apps/application/components/LoadMoreComponent/LoadMoreComponent';
import { handleTagShare } from 'apps/application/shared';
import { usePrsdigg, useUserAgent } from 'apps/shared';
import {
  Article,
  useTaggedArticleConnectionQuery,
  useToggleSubscribeTagActionMutation,
} from 'graphqlTypes';
import React, { useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useParams } from 'react-router-dom';

export default function TagPage() {
  const { id } = useParams<{ id: string }>();
  const { t } = useTranslation();
  const { appId, pageTitle } = usePrsdigg();
  const { mixinEnv } = useUserAgent();
  const { loading, data, fetchMore } = useTaggedArticleConnectionQuery({
    variables: { tagId: id, filter: 'lately' },
  });
  const [toggleSubscribeTagAction] = useToggleSubscribeTagActionMutation();

  useEffect(() => {
    return () => (document.title = pageTitle);
  }, [id]);

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    tag,
    articleConnection: {
      nodes: articles,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  document.title = `#${tag.name} 话题文章`;

  return (
    <div>
      <Card
        style={{
          borderTop: `3px solid ${tag.color}`,
          borderTopLeftRadius: 10,
          borderTopRightRadius: 10,
        }}
      >
        <div>
          <Typography.Title level={5}>#{tag.name}</Typography.Title>
        </div>
        <div style={{ marginBottom: 15 }}>
          <Space split={<Divider type='vertical' />}>
            <Typography.Text type='secondary'>
              {t('tag.articles_count')}: {tag.articlesCount}
            </Typography.Text>
            <Typography.Text type='secondary'>
              {t('tag.subscribers_count')}: {tag.subscribersCount}
            </Typography.Text>
          </Space>
        </div>
        <div style={{ textAlign: 'right' }}>
          <Button
            type='link'
            icon={<AlertOutlined />}
            size='small'
            onClick={() =>
              toggleSubscribeTagAction({
                variables: { input: { id } },
              })
            }
          >
            {tag.subscribed ? t('unsubscribe') : t('subscribe')}
          </Button>
          <Button
            onClick={() => handleTagShare(tag, mixinEnv, appId)}
            type='link'
            size='small'
            icon={<ShareAltOutlined />}
          >
            {t('share')}
          </Button>
        </div>
      </Card>
      <List
        size='large'
        itemLayout='vertical'
        dataSource={articles}
        loadMore={
          <LoadMoreComponent
            hasNextPage={hasNextPage}
            loading={loading}
            fetchMore={() => {
              fetchMore({
                variables: {
                  after: endCursor,
                  filter: 'lately',
                },
              });
            }}
          />
        }
        renderItem={(article: Partial<Article>) => (
          <ArticleListItemComponent article={article} />
        )}
      />
    </div>
  );
}
