import { Article, useArticleConnectionQuery } from '@/graphql';
import ArticleListItemComponent from '@application/components/ArticleListItemComponent/ArticleListItemComponent';
import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import { Button, Empty, Input, List } from 'antd';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';

export default function SearchPage() {
  const { t } = useTranslation();
  const [query, setQuery] = useState('');
  return (
    <div style={{ marginTop: 20 }}>
      <div style={{ marginBottom: '1rem' }}>
        <Input.Search
          size='large'
          enterButton={t('searchPage.enterBtn')}
          placeholder={t('searchPage.placeholder')}
          onSearch={(value) => setQuery(value)}
        />
      </div>
      {query ? <SearchResultCompoent query={query} /> : <Empty />}
    </div>
  );
}

function SearchResultCompoent(props: { query?: string }) {
  const { t } = useTranslation();
  const { query } = props;
  const { loading, data, fetchMore } = useArticleConnectionQuery({
    variables: { query, order: 'default' },
  });
  if (loading) {
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
                  updateQuery: (prev, { fetchMoreResult }) => {
                    if (!fetchMoreResult) {
                      return prev;
                    }
                    const connection = fetchMoreResult.articleConnection;
                    connection.nodes = prev.articleConnection.nodes.concat(
                      connection.nodes,
                    );
                    return Object.assign({}, prev, {
                      articleConnection: connection,
                    });
                  },
                  variables: {
                    after: endCursor,
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
