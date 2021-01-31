import LoadingComponent from '@dashboard/components/LoadingComponent/LoadingComponent';
import {
  Article,
  MyArticleConnectionQueryHookResult,
  useMyArticleConnectionQuery,
} from '@graphql';
import { Avatar, Button, List, Row, Space } from 'antd';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';

export default function MyBoughtArticlesComponent() {
  const { t, i18n } = useTranslation();
  moment.locale(i18n.language);
  const {
    data,
    loading,
    fetchMore,
  }: MyArticleConnectionQueryHookResult = useMyArticleConnectionQuery({
    variables: { type: 'reader' },
  });

  if (loading) {
    return <LoadingComponent />;
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
                  variables: {
                    after: endCursor,
                    type: 'reader',
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
        <List.Item key={article.uuid}>
          <List.Item.Meta
            style={{ marginBottom: 0 }}
            avatar={
              <Avatar src={article.author.avatarUrl}>
                {article.author.name[0]}
              </Avatar>
            }
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
              <a
                style={{ color: 'inherit' }}
                href={`/articles/${article.uuid}`}
                target='_blank'
              >
                {article.title}
              </a>
            </Space>
          </h3>
        </List.Item>
      )}
    />
  );
}
