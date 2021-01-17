import { AlertOutlined, ShareAltOutlined } from '@ant-design/icons';
import ArticleListItemComponent from '@application/components/ArticleListItemComponent/ArticleListItemComponent';
import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import LoadMoreComponent from '@application/components/LoadMoreComponent/LoadMoreComponent';
import { handleTagShare, PAGE_TITLE } from '@application/shared';
import {
  Article,
  useTaggedArticleConnectionQuery,
  useToggleSubscribeTagActionMutation,
} from '@graphql';
import { usePrsdigg, useUserAgent } from '@shared';
import { Button, Card, Divider, List, Space, Typography } from 'antd';
import React, { useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useParams } from 'react-router-dom';

export default function TagPage() {
  const { id } = useParams<{ id: string }>();
  const { t } = useTranslation();
  const { appId } = usePrsdigg();
  const { mixinEnv } = useUserAgent();
  const { loading, data, fetchMore } = useTaggedArticleConnectionQuery({
    variables: { tagId: id, order: 'lately' },
  });
  const [toggleSubscribeTagAction] = useToggleSubscribeTagActionMutation();

  useEffect(() => {
    return () => (document.title = PAGE_TITLE);
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
              {t('tag.articlesCount')}: {tag.articlesCount}
            </Typography.Text>
            <Typography.Text type='secondary'>
              {t('tag.subscribersCount')}: {tag.subscribersCount}
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
            {tag.subscribed
              ? t('common.unsubscribeBtn')
              : t('common.subscribeBtn')}
          </Button>
          <Button
            onClick={() => handleTagShare(tag, mixinEnv, appId)}
            type='link'
            size='small'
            icon={<ShareAltOutlined />}
          >
            {t('common.shareBtn')}
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
                  order: 'lately',
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
