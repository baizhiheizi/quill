import { Button, List, message, Popconfirm, Tag } from 'antd';
import LoadingComponent from 'apps/dashboard/components/LoadingComponent/LoadingComponent';
import { useUserAgent } from 'apps/shared';
import {
  Article,
  HideArticleMutationHookResult,
  MyArticleConnectionQueryHookResult,
  PublishArticleMutationHookResult,
  useDeleteArticleMutation,
  useHideArticleMutation,
  useMyArticleConnectionQuery,
  usePublishArticleMutation,
} from 'graphqlTypes';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useHistory } from 'react-router-dom';

export default function MyArticlesComponent(props: {
  state?: 'drafted' | 'published' | 'hidden' | 'blocked';
}) {
  const { t, i18n } = useTranslation();
  const history = useHistory();
  const { isMobile } = useUserAgent();
  moment.locale(i18n.language);
  const {
    data,
    loading,
    fetchMore,
    refetch,
  }: MyArticleConnectionQueryHookResult = useMyArticleConnectionQuery({
    fetchPolicy: 'cache-and-network',
    variables: { type: 'author', state: props.state || 'published' },
  });
  const [hideArticle, { loading: hiding }]: HideArticleMutationHookResult =
    useHideArticleMutation({
      update(_, { data: { error: err } }) {
        if (err) {
          message.error(err);
        } else {
          message.success(t('success_hidden_article'));
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
        message.success(t('success_published_article'));
        refetch();
      }
    },
  });
  const [deleteArticle] = useDeleteArticleMutation({
    update: () => refetch(),
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
              {t('load_more')}
            </Button>
          </div>
        )
      }
      renderItem={(article: Partial<Article>) => (
        <List.Item
          key={article.uuid}
          actions={
            article.state === 'blocked'
              ? [<Link to={`/articles/${article.uuid}`}>{t('detail')}</Link>]
              : article.state === 'drafted'
              ? [
                  <Link to={`/articles/${article.uuid}/edit`}>
                    {t('edit')}
                  </Link>,
                  <Popconfirm
                    title={t('confirm_to_delete')}
                    onConfirm={() =>
                      deleteArticle({
                        variables: { input: { uuid: article.uuid } },
                      })
                    }
                  >
                    <a>{t('delete')}</a>
                  </Popconfirm>,
                ]
              : [
                  <Link to={`/articles/${article.uuid}`}>{t('detail')}</Link>,
                  <span>
                    {article.state === 'hidden' && (
                      <Popconfirm
                        title={t('confirm_to_publish')}
                        disabled={publishing}
                        onConfirm={() =>
                          publishArticle({
                            variables: { input: { uuid: article.uuid } },
                          })
                        }
                      >
                        <a>{t('publish')}</a>
                      </Popconfirm>
                    )}
                    {article.state === 'published' && (
                      <Popconfirm
                        title={t('confirm_to_hide')}
                        disabled={hiding}
                        onConfirm={() =>
                          hideArticle({
                            variables: { input: { uuid: article.uuid } },
                          })
                        }
                      >
                        <a>{t('hide')}</a>
                      </Popconfirm>
                    )}
                  </span>,
                  <Link to={`/articles/${article.uuid}/edit`}>
                    {t('edit')}
                  </Link>,
                ]
          }
        >
          <List.Item.Meta
            title={
              <a
                onClick={() => {
                  if (article.state === 'drafted') {
                    history.push(`/articles/${article.uuid}/edit`);
                  }
                }}
              >
                {article.title || 'untitled'}
              </a>
            }
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
