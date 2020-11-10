import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import { Article, useUserArticleConnectionQuery } from '@graphql';
import { Avatar, Button, List, Row, Space } from 'antd';
import moment from 'moment';
import React from 'react';
import { Link } from 'react-router-dom';
moment.locale('zh-cn');

export default function ArticlesComponent(props: {
  type: 'author' | 'reader';
  mixinId: string;
}) {
  const { type, mixinId } = props;
  const { data, loading, fetchMore } = useUserArticleConnectionQuery({
    variables: { type, mixinId },
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
                    const connection = fetchMoreResult.userArticleConnection;
                    connection.nodes = prev.userArticleConnection.nodes.concat(
                      connection.nodes,
                    );
                    return Object.assign({}, prev, {
                      userArticleConnection: connection,
                    });
                  },
                  variables: {
                    after: endCursor,
                    type,
                  },
                });
              }}
            >
              加载更多
            </Button>
          </div>
        )
      }
      renderItem={(article: Partial<Article>) => (
        <List.Item key={article.uuid}>
          <List.Item.Meta
            style={{ marginBottom: 0 }}
            avatar={<Avatar src={article.author.avatarUrl} />}
            title={
              <Row>
                <div>
                  <div>{article.author.name}</div>
                  <div style={{ fontSize: '0.8rem', color: '#aaa' }}>
                    {moment(article.createdAt).fromNow()}
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
