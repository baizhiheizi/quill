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
    <>
      {myArticle.state === 'drafted' ? (
        <DraftedArticleEditComponent article={myArticle} />
      ) : (
        <PublishedArticleEditComponent article={myArticle} />
      )}
    </>
  );
}
