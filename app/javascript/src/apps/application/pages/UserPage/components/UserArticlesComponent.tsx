import { AlertOutlined } from '@ant-design/icons';
import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import { useCurrentUser } from '@application/shared';
import {
  Article,
  useToggleAuthoringSubscribeUserActionMutation,
  useToggleReadingSubscribeUserActionMutation,
  useUserArticleConnectionQuery,
} from '@graphql';
import { Avatar, Button, List, message, Row, Space } from 'antd';
import moment from 'moment';
import React from 'react';
import { Link } from 'react-router-dom';
moment.locale('zh-cn');

export default function UserArticlesComponent(props: {
  type: 'author' | 'reader';
  mixinId: string;
  authoringSubscribed?: boolean;
  readingSubscribed?: boolean;
  refetchUser?: () => any;
}) {
  const {
    type,
    mixinId,
    authoringSubscribed,
    readingSubscribed,
    refetchUser,
  } = props;
  const currentUser = useCurrentUser();
  const { data, loading, fetchMore } = useUserArticleConnectionQuery({
    variables: { type, mixinId },
  });
  const [
    toggleAuthoringSubscribeUserAction,
  ] = useToggleAuthoringSubscribeUserActionMutation({
    update(
      _,
      {
        data: {
          toggleAuthoringSubscribeUserAction: { error },
        },
      },
    ) {
      if (error) {
        message.error(error);
      } else {
        message.success(authoringSubscribed ? '已取消订阅' : '成功订阅');
        refetchUser();
      }
    },
  });
  const [
    toggleReadingSubscribeUserAction,
  ] = useToggleReadingSubscribeUserActionMutation({
    update(
      _,
      {
        data: {
          toggleReadingSubscribeUserAction: { error },
        },
      },
    ) {
      if (error) {
        message.error(error);
      } else {
        message.success(readingSubscribed ? '已取消订阅' : '成功订阅');
        refetchUser();
      }
    },
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
    <div>
      <div style={{ textAlign: 'right', color: '#aaa' }}>
        {currentUser && currentUser.mixinId !== mixinId && type === 'author' && (
          <Button
            type='primary'
            danger={authoringSubscribed}
            shape='round'
            icon={<AlertOutlined />}
            onClick={() =>
              toggleAuthoringSubscribeUserAction({
                variables: { input: { mixinId } },
              })
            }
          >
            {authoringSubscribed ? '取消订阅' : '订阅更新'}
          </Button>
        )}
        {currentUser && currentUser.mixinId !== mixinId && type === 'reader' && (
          <Button
            type='primary'
            danger={readingSubscribed}
            shape='round'
            icon={<AlertOutlined />}
            onClick={() =>
              toggleReadingSubscribeUserAction({
                variables: { input: { mixinId } },
              })
            }
          >
            {readingSubscribed ? '取消订阅' : '订阅更新'}
          </Button>
        )}
      </div>
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
    </div>
  );
}
