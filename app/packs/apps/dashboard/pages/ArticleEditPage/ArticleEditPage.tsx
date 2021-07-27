import { PageHeader } from 'antd';
import DraftedArticleEditComponent from 'apps/dashboard/components/DraftedArticleEditComponent/DraftedArticleEditComponent';
import LoadingComponent from 'apps/dashboard/components/LoadingComponent/LoadingComponent';
import PublishedArticleEditComponent from 'apps/dashboard/components/PublishedArticleEditComponent/PublishedArticleEditComponent';
import { useMyArticleQuery } from 'graphqlTypes';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useHistory, useParams } from 'react-router-dom';

export default function ArticleEditPage() {
  const { uuid } = useParams<{ uuid: string }>();
  const history = useHistory();
  const { t } = useTranslation();
  const { data, loading } = useMyArticleQuery({
    fetchPolicy: 'network-only',
    variables: { uuid },
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const { myArticle } = data;

  return (
    <div>
      <PageHeader
        title={t('edit_article')}
        breadcrumb={{
          routes: [
            { path: '/articles', breadcrumbName: t('articles_manage') },
            {
              path: `/articles/${uuid}`,
              breadcrumbName:
                myArticle.title ||
                moment(myArticle.createdAt).format('YYYY-MM-DD HH:MM'),
            },
            { path: '', breadcrumbName: t('edit_article') },
          ],
          itemRender: (route, _params, routes, _paths) => {
            const last = routes.indexOf(route) === routes.length - 1;
            return last ? (
              <span>{route.breadcrumbName}</span>
            ) : (
              <Link to={route.path}>{route.breadcrumbName}</Link>
            );
          },
        }}
      />
      {myArticle.state === 'drafted' ? (
        <DraftedArticleEditComponent article={myArticle} />
      ) : (
        <PublishedArticleEditComponent article={myArticle} />
      )}
    </div>
  );
}
