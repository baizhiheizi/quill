import { AlertOutlined } from '@ant-design/icons';
import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import {
  Article,
  useToggleAuthoringSubscribeUserActionMutation,
  useToggleReadingSubscribeUserActionMutation,
  useUserArticleConnectionQuery,
} from '@graphql';
import { useCurrentUser } from '@shared';
import { Avatar, Button, List, message, Row, Space } from 'antd';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';

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
  const { t, i18n } = useTranslation();
  moment.locale(i18n.language);
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
        message.success(
          authoringSubscribed
            ? t('messages.successUnsubscribed')
            : t('messages.successSubscribed'),
        );
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
        message.success(
          readingSubscribed
            ? t('messages.successUnsubscribed')
            : t('messages.successSubscribed'),
        );
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
            {authoringSubscribed
              ? t('common.unsubscribeBtn')
              : t('common.subscribeBtn')}
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
            {readingSubscribed
              ? t('common.unsubscribeBtn')
              : t('common.subscribeBtn')}
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
                    variables: {
                      after: endCursor,
                      type,
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
