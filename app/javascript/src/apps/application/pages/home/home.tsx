import {
  MessageOutlined,
  MoneyCollectOutlined,
  ReadOutlined,
  ShareAltOutlined,
} from '@ant-design/icons';
import {
  Article,
  ArticleConnectionQueryHookResult,
  useArticleConnectionQuery,
} from '@graphql';
import { Avatar, Button, List, Row, Space, Tabs } from 'antd';
import moment from 'moment';
import React from 'react';
import { Link } from 'react-router-dom';
import { Loading } from '../../components';
import { handleShare, PRS_ICON_URL, useMixin, usePrsdigg } from '../../shared';

function ArticleList(props: { order: 'default' | 'lately' | 'revenue' }) {
  const { order } = props;
  const { mixinEnv } = useMixin();
  const { appId } = usePrsdigg();
  const {
    data,
    loading,
    fetchMore,
  }: ArticleConnectionQueryHookResult = useArticleConnectionQuery({
    fetchPolicy: 'network-only',
    notifyOnNetworkStatusChange: true,
    variables: {
      order,
    },
  });

  if (!data && loading) {
    return <Loading />;
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
                    order,
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
          actions={[
            <Space>
              <ReadOutlined />
              <span>{article.ordersCount}次付费</span>
            </Space>,
            <Space>
              <MoneyCollectOutlined />
              <span>{article.revenue.toFixed(2)}</span>
            </Space>,
            <Space>
              <MessageOutlined />
              <span>{article.commentsCount}</span>
            </Space>,
            <Button
              size='small'
              type='text'
              icon={
                <ShareAltOutlined
                  onClick={() => {
                    handleShare(article, Boolean(mixinEnv), appId);
                  }}
                />
              }
            />,
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
          <Link style={{ color: 'initial' }} to={`/articles/${article.uuid}`}>
            <h2>{article.title}</h2>
            <p>{article.intro}</p>
          </Link>
        </List.Item>
      )}
    />
  );
}

export function Home() {
  return (
    <Tabs defaultActiveKey='default'>
      <Tabs.TabPane tab='综合排序' key='default'>
        <ArticleList order='default' />
      </Tabs.TabPane>
      <Tabs.TabPane tab='最新优先' key='lately'>
        <ArticleList order='lately' />
      </Tabs.TabPane>
      <Tabs.TabPane tab='营收最多' key='revenue'>
        <ArticleList order='revenue' />
      </Tabs.TabPane>
    </Tabs>
  );
}
