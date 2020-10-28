import {
  Article,
  ArticleConnectionQueryHookResult,
  useArticleConnectionQuery,
} from '@/graphql';
import { MoneyCollectOutlined, ReadOutlined } from '@ant-design/icons';
import { Avatar, List, Space, Spin } from 'antd';
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
  }: ArticleConnectionQueryHookResult = useArticleConnectionQuery({
    fetchPolicy: 'network-only',
  });

  if (loading) {
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
      bordered
      size='large'
      itemLayout='vertical'
      dataSource={articles}
      renderItem={(article: Partial<Article>) => (
        <List.Item
          key={article.uuid}
          onClick={() => history.push(`/articles/${article.uuid}`)}
          actions={[
            <Space>
              <MoneyCollectOutlined />
              <span>营收{article.revenue.toFixed(2)}PRS</span>
            </Space>,
            <Space>
              <Avatar size='small' src={PRS_ICON_URL} />
              <span>价格:{article.price.toFixed(2)}</span>
            </Space>,
          ]}
        >
          <List.Item.Meta
            style={{ marginBottom: 0 }}
            avatar={<Avatar src={article.author.avatarUrl} />}
            title={
              <div>
                <div>{article.author.name}</div>
                <div style={{ fontSize: '0.8rem', color: '#aaa' }}>
                  {moment(article.createdAt).fromNow()}
                </div>
              </div>
            }
          />
          <h2>{article.title}</h2>
          <p>{article.intro}</p>
        </List.Item>
      )}
    />
  );
}
