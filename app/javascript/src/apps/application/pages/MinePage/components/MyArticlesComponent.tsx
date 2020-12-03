import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import {
  Article,
  HideArticleMutationHookResult,
  MyArticleConnectionQueryHookResult,
  PublishArticleMutationHookResult,
  useHideArticleMutation,
  useMyArticleConnectionQuery,
  usePublishArticleMutation,
} from '@graphql';
import {
  Avatar,
  Button,
  List,
  message,
  Popconfirm,
  Row,
  Space,
  Tag,
} from 'antd';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';

export default function MyArticlesComponent(props: {
  type: 'author' | 'reader';
}) {
  const { type } = props;
  const { t, i18n } = useTranslation();
  moment.locale(i18n.language);
  const {
    data,
    loading,
    fetchMore,
    refetch,
  }: MyArticleConnectionQueryHookResult = useMyArticleConnectionQuery({
    variables: { type },
  });
  const [
    hideArticle,
    { loading: hiding },
  ]: HideArticleMutationHookResult = useHideArticleMutation({
    update(_, { data: { error: err } }) {
      if (err) {
        message.error(err);
      } else {
        message.success(t('messages.successHiddenArticle'));
        refetch();
      }
    },
  });
  const [
    publishArticle,
    { loading: publishing },
  ]: PublishArticleMutationHookResult = usePublishArticleMutation({
    update(_, { data: { error: err } }) {
      if (err) {
        message.error(err);
      } else {
        message.success(t('messages.successPublishedArticle'));
        refetch();
      }
    },
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
        <List.Item
          key={article.uuid}
          actions={
            type === 'author' &&
            (article.state === 'blocked'
              ? [
                  <Link to={`/articles/${article.uuid}`}>
                    {t('common.detailBtn')}
                  </Link>,
                ]
              : [
                  <Link to={`/articles/${article.uuid}`}>
                    {t('common.detailBtn')}
                  </Link>,
                  <span>
                    {article.state === 'hidden' ? (
                      <Popconfirm
                        title={t('minePage.publishConfirm')}
                        disabled={publishing}
                        onConfirm={() =>
                          publishArticle({
                            variables: { input: { uuid: article.uuid } },
                          })
                        }
                      >
                        <a>{t('minePage.publishBtn')}</a>
                      </Popconfirm>
                    ) : (
                      <Popconfirm
                        title={t('minePage.hideConfirm')}
                        disabled={hiding}
                        onConfirm={() =>
                          hideArticle({
                            variables: { input: { uuid: article.uuid } },
                          })
                        }
                      >
                        <a>{t('minePage.hideBtn')}</a>
                      </Popconfirm>
                    )}
                  </span>,
                  <Link to={`/articles/${article.uuid}/edit`}>
                    {t('common.editBtn')}
                  </Link>,
                ])
          }
        >
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
              {type === 'author' && (
                <Tag
                  color={
                    article.state === 'published'
                      ? 'success'
                      : article.state === 'blocked'
                      ? 'error'
                      : 'warning'
                  }
                >
                  {t(`article.state.${article.state}`)}
                </Tag>
              )}
              {type === 'author' ? (
                article.title
              ) : (
                <Link
                  style={{ color: 'inherit' }}
                  to={`/articles/${article.uuid}`}
                >
                  {article.title}
                </Link>
              )}
            </Space>
          </h3>
        </List.Item>
      )}
    />
  );
}
