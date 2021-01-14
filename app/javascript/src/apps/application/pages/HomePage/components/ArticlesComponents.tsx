import ArticleListItemComponent from '@application/components/ArticleListItemComponent/ArticleListItemComponent';
import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import LoadMoreComponent from '@application/components/LoadMoreComponent/LoadMoreComponent';
import {
  Article,
  ArticleConnectionQueryHookResult,
  useArticleConnectionQuery,
} from '@graphql';
import { List } from 'antd';
import React from 'react';

export default function ArticlesComponent(props: {
  order: 'default' | 'lately' | 'revenue';
}) {
  const { order } = props;
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
        <LoadMoreComponent
          hasNextPage={hasNextPage}
          loading={loading}
          fetchMore={() => {
            fetchMore({
              variables: {
                after: endCursor,
                order,
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
