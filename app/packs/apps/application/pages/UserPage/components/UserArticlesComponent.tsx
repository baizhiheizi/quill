import { Avatar, List, Row, Space } from 'antd';
import LoadingComponent from 'apps/application/components/LoadingComponent/LoadingComponent';
import LoadMoreComponent from 'apps/application/components/LoadMoreComponent/LoadMoreComponent';
import { useCurrentUser } from 'apps/shared';
import { Article, useUserArticleConnectionQuery } from 'graphqlTypes';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';

export default function UserArticlesComponent(props: {
  type: 'author' | 'reader';
  uid: string;
}) {
  const { type, uid } = props;
  const { t, i18n } = useTranslation();
  moment.locale(i18n.language);
  const { currentUser } = useCurrentUser();
  const { data, loading, fetchMore } = useUserArticleConnectionQuery({
    variables: { type, uid },
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    userArticleConnection: {
      nodes: articles,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  return (
    <List
      size='small'
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
                type,
              },
            });
          }}
        />
      }
      renderItem={(article: Partial<Article>) => (
        <List.Item key={article.uuid}>
          <List.Item.Meta
            style={{ marginBottom: 0 }}
            avatar={
              <Avatar src={article.author.avatar}>
                {article.author.name[0]}
              </Avatar>
            }
            title={
              <Row>
                <div>
                  <div>{article.author.name}</div>
                  <div style={{ fontSize: '0.8rem', color: '#aaa' }}>
                    {moment(article.publishedAt).fromNow()}
                  </div>
                </div>
              </Row>
            }
          />
          <h3>
            <Space>
              <Link
                style={{ color: 'inherit' }}
                to={`/articles/${article.uuid}`}
              >
                {article.title}
              </Link>
            </Space>
          </h3>
        </List.Item>
      )}
    />
  );
}
