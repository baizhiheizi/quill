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
import { useHistory, useLocation } from 'react-router-dom';

export default function ArticlesPage() {
  const location = useLocation();
  const history = useHistory();
  const tagParam = new URLSearchParams(history.location.search).get('tag');
  const { t } = useTranslation();
  const { appId, pageTitle } = usePrsdigg();
  const { mixinEnv } = useUserAgent();
  const { loading, data, fetchMore, refetch } = useTaggedArticleConnectionQuery(
    {
      variables: { tag: tagParam, filter: 'lately' },
    },
  );
  const [toggleSubscribeTagAction] = useToggleSubscribeTagActionMutation();

  useEffect(() => {
    const _tagParam = new URLSearchParams(location.search).get('tag');
    refetch({ variables: { tag: _tagParam, filter: 'lately' } });
    return () => (document.title = pageTitle);
  }, [location]);

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

  document.title = `#${tag.name} | ${document.title}`;

  return (
    <>
      {tag && (
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
          <div className='mb-4'>
            <Space split={<Divider type='vertical' />}>
              <Typography.Text type='secondary'>
                {t('tag.articles_count')}: {tag.articlesCount}
              </Typography.Text>
              <Typography.Text type='secondary'>
                {t('tag.subscribers_count')}: {tag.subscribersCount}
              </Typography.Text>
            </Space>
          </div>
          <div className='text-right'>
            <Button
              type='link'
              icon={<AlertOutlined />}
              size='small'
              onClick={() =>
                toggleSubscribeTagAction({
                  variables: { input: { id: tag.id } },
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
      )}
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
    </>
  );
}
