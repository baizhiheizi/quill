import ArticleListItemComponent from '@/apps/application/components/ArticleListItemComponent/ArticleListItemComponent';
import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import {
  Article,
  ArticleConnectionQueryHookResult,
  useArticleConnectionQuery,
} from '@graphql';
import { Button, List } from 'antd';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function ArticlesComponent(props: {
  order: 'default' | 'lately' | 'revenue';
}) {
  const { order } = props;
  const { t, i18n } = useTranslation();
  moment.locale(i18n.language);
  const {
    data,
    loading,
    fetchMore,
  }: ArticleConnectionQueryHookResult = useArticleConnectionQuery({
    notifyOnNetworkStatusChange: true,
    variables: {
      order,
    },
  });

  if (!data && loading) {
    return <LoadingComponent />;
  }

  const {
    articleConnection: {
      nodes: articles,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;
  return (
    <List
      size='large'
      itemLayout='vertical'
      dataSource={articles}
      loadMore={
        hasNextPage && (
          <div
            style={{
              textAlign: 'center',
              marginTop: 12,
              height: 32,
              lineHeight: '32px',
            }}
          >
            <Button
              loading={loading}
              onClick={() => {
                fetchMore({
                  variables: {
                    after: endCursor,
                    order,
                  },
                });
              }}
            >
              {t('common.loadMore')}
            </Button>
          </div>
        )
      }
      renderItem={(article: Partial<Article>) => (
        <ArticleListItemComponent article={article} />
      )}
    />
  );
}
