import {
  Article,
  ArticleConnectionQueryHookResult,
  useMyArticleConnectionQuery,
} from '@/graphql';
import { Avatar, Button, List, Row } from 'antd';
import moment from 'moment';
import React from 'react';
import { useHistory } from 'react-router-dom';
import { Loading } from '../../components';

export function Articles(props: { type: 'author' | 'reader' }) {
  const { type } = props;
  const history = useHistory();
  const {
    data,
    loading,
    fetchMore,
  }: ArticleConnectionQueryHookResult = useMyArticleConnectionQuery({
    variables: { type },
  });

  if (loading) {
    return <Loading />;
  }

  const {
    myArticleConnection: {
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
                    const connection = fetchMoreResult.myArticleConnection;
                    connection.nodes = prev.myArticleConnection.nodes.concat(
                      connection.nodes,
                    );
                    return Object.assign({}, prev, {
                      myArticleConnection: connection,
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
        <List.Item
          key={article.uuid}
          onClick={() => history.push(`/articles/${article.uuid}`)}
        >
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
          <h3>{article.title}</h3>
        </List.Item>
      )}
    />
  );
}
