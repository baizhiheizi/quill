import {
  Article,
  ArticleConnectionQueryHookResult,
  useArticleConnectionQuery,
} from '@/graphql';
import { MoneyCollectOutlined, ReadOutlined } from '@ant-design/icons';
import { Avatar, Button, List, Row, Space, Spin } from 'antd';
import moment from 'moment';
import React from 'react';
import { useHistory } from 'react-router-dom';
import { PRS_ICON_URL, useCurrentUser } from '../../shared';

export function Home() {
  const currentUser = useCurrentUser();
  const history = useHistory();
  const {
    data,
    loading,
    fetchMore,
  }: ArticleConnectionQueryHookResult = useArticleConnectionQuery({
    fetchPolicy: 'network-only',
    notifyOnNetworkStatusChange: true,
  });

  if (!data && loading) {
    return <Spin />;
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
              Load More
            </Button>
          </div>
        )
      }
      renderItem={(article: Partial<Article>) => (
        <List.Item
          key={article.uuid}
          onClick={() => history.push(`/articles/${article.uuid}`)}
          actions={[
            <Space>
              <ReadOutlined />
              <span>{article.ordersCount}次付费</span>
            </Space>,
            <Space>
              <MoneyCollectOutlined />
              <span>营收{article.revenue.toFixed(2)}PRS</span>
            </Space>,
          ]}
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
                <Space style={{ marginLeft: 'auto' }}>
                  <Avatar size='small' src={PRS_ICON_URL} />
                  <span>{article.price.toFixed(2)}</span>
                </Space>
              </Row>
            }
          />
          <h2>{article.title}</h2>
          <p>{article.intro}</p>
        </List.Item>
      )}
    />
  );
}
