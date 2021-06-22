import { Empty, Input, List } from 'antd';
import ArticleListItemComponent from 'apps/application/components/ArticleListItemComponent/ArticleListItemComponent';
import LoadingComponent from 'apps/application/components/LoadingComponent/LoadingComponent';
import LoadMoreComponent from 'apps/application/components/LoadMoreComponent/LoadMoreComponent';
import { Article, useArticleConnectionQuery } from 'graphqlTypes';
import Mark from 'mark.js';
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';

export default function SearchPage() {
  const { t } = useTranslation();
  const [query, setQuery] = useState('');
  return (
    <div style={{ marginTop: 20 }}>
      <div style={{ marginBottom: '1rem' }}>
        <Input.Search
          size='large'
          enterButton={t('search')}
          placeholder={t('search_placeholder')}
          onSearch={(value) => setQuery(value)}
        />
      </div>
      {query ? <SearchResultCompoent query={query} /> : <Empty />}
    </div>
  );
}

function SearchResultCompoent(props: { query?: string }) {
  const { query } = props;
  const { loading, data, fetchMore } = useArticleConnectionQuery({
    variables: { query, filter: 'default' },
  });

  useEffect(() => {
    const context = document.querySelector('div.search-result');
    const marker = new Mark(context as any);
    marker.mark(query);
  }, [query, data]);

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
    <div className='search-result'>
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
