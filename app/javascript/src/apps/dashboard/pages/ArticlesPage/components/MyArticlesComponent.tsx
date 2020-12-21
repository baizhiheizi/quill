import { useUserAgent } from '@/shared';
import LoadingComponent from '@dashboard/components/LoadingComponent/LoadingComponent';
import {
  Article,
  HideArticleMutationHookResult,
  MyArticleConnectionQueryHookResult,
  PublishArticleMutationHookResult,
  useHideArticleMutation,
  useMyArticleConnectionQuery,
  usePublishArticleMutation,
} from '@graphql';
import { Button, List, message, Popconfirm, Tag } from 'antd';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';

export default function MyArticlesComponent() {
  const { t, i18n } = useTranslation();
  const { isMobile } = useUserAgent();
  moment.locale(i18n.language);
  const {
    data,
    loading,
    fetchMore,
    refetch,
  }: MyArticleConnectionQueryHookResult = useMyArticleConnectionQuery({
    variables: { type: 'author' },
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
      itemLayout={isMobile.phone ? 'vertical' : 'horizontal'}
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
                    type: 'author',
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
            article.state === 'blocked'
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
                        title={t('dashboard.articlesPage.publishConfirm')}
                        disabled={publishing}
                        onConfirm={() =>
                          publishArticle({
                            variables: { input: { uuid: article.uuid } },
                          })
                        }
                      >
                        <a>{t('dashboard.articlesPage.publishBtn')}</a>
                      </Popconfirm>
                    ) : (
                      <Popconfirm
                        title={t('dashboard.articlesPage.hideConfirm')}
                        disabled={hiding}
                        onConfirm={() =>
                          hideArticle({
                            variables: { input: { uuid: article.uuid } },
                          })
                        }
                      >
                        <a>{t('dashboard.articlesPage.hideBtn')}</a>
                      </Popconfirm>
                    )}
                  </span>,
                  <Link to={`/articles/${article.uuid}/edit`}>
                    {t('common.editBtn')}
                  </Link>,
                ]
          }
        >
          <List.Item.Meta
            title={article.title}
            description={moment(article.createdAt).format(
              'YYYY-MM-DD HH:mm:ss',
            )}
          />
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
        </List.Item>
      )}
    />
  );
}
