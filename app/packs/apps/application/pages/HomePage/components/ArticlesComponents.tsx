import { List } from 'antd';
import ArticleListItemComponent from 'apps/application/components/ArticleListItemComponent/ArticleListItemComponent';
import LoadingComponent from 'apps/application/components/LoadingComponent/LoadingComponent';
import LoadMoreComponent from 'apps/application/components/LoadMoreComponent/LoadMoreComponent';
import {
  Article,
  ArticleConnectionQueryHookResult,
  useArticleConnectionQuery,
} from 'graphqlTypes';
import React from 'react';

export default function ArticlesComponent(props: {
  filter: 'default' | 'lately' | 'revenue' | 'subscribed';
  timeRange?: string;
}) {
  const { filter, timeRange } = props;
  const { data, loading, fetchMore }: ArticleConnectionQueryHookResult =
    useArticleConnectionQuery({
      notifyOnNetworkStatusChange: true,
      variables: {
        filter,
        timeRange,
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
        <LoadMoreComponent
          hasNextPage={hasNextPage}
          loading={loading}
          fetchMore={() => {
            fetchMore({
              variables: {
                after: endCursor,
                filter,
              },
            });
          }}
        />
      }
      renderItem={(article: Partial<Article>) => (
        <ArticleListItemComponent article={article} />
      )}
    />
  );
}
