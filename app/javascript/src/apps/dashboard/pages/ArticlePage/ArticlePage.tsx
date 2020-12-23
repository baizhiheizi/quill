import LoadingComponent from '@dashboard/components/LoadingComponent/LoadingComponent';
import { updateActiveMenu } from '@dashboard/shared';
import { useMyArticleQuery } from '@graphql';
import { Button, Descriptions, PageHeader, Tabs, Tag } from 'antd';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useParams } from 'react-router-dom';
import moment from 'moment';
import ArticleOrdersComponent from './components/ArticleOrdersComponent';
import ArticleCommentsComponent from './components/ArticleCommentsComponent';

export default function ArticlePage() {
  updateActiveMenu('articles');
  const { t, i18n } = useTranslation();
  moment.locale(i18n.language);
  const { uuid } = useParams<{ uuid: string }>();
  const { loading, data } = useMyArticleQuery({ variables: { uuid } });

  if (loading) {
    return <LoadingComponent />;
  }

  const { myArticle: article } = data;

  return (
    <div>
      <PageHeader
        title={t('dashboard.pages.article')}
        extra={[
          <Button key='edit' type='primary'>
            <Link to={`/articles/${uuid}/edit`}>{t('common.editBtn')}</Link>
          </Button>,
          <Button key='view'>
            <a href={`/articles/${uuid}`} target='_blank'>
              {t('common.viewBtn')}
            </a>
          </Button>,
        ]}
        breadcrumb={{
          routes: [
            { path: '/articles', breadcrumbName: t('dashboard.menu.articles') },
            { path: '', breadcrumbName: article.title },
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
      <div style={{ marginBottom: '1rem' }}>
        <Descriptions
          bordered
          size='small'
          column={{ xxl: 4, xl: 3, lg: 3, md: 3, sm: 2, xs: 1 }}
        >
          <Descriptions.Item label={t('article.stateText')}>
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
          </Descriptions.Item>
          <Descriptions.Item label={t('article.createdAt')}>
            {moment(article.createdAt).format('YYYY-MM-DD HH:mm:ss')}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.updatedAt')}>
            {moment(article.updatedAt).format('YYYY-MM-DD HH:mm:ss')}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.price')}>
            {article.price}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.buyOrdersCount')}>
            {article.buyOrders.totalCount}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.rewardOrdersCount')}>
            {article.rewardOrders.totalCount}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.revenue')}>
            {article.revenue}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.authorRevenueAmount')}>
            {article.authorRevenueAmount}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.readerRevenueAmount')}>
            {article.readerRevenueAmount}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.commentsCount')}>
            {article.comments.totalCount}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.upvotesCount')}>
            {article.upvotesCount}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.downvotesCount')}>
            {article.downvotesCount}
          </Descriptions.Item>
        </Descriptions>
      </div>
      <div>
        <Tabs>
          <Tabs.TabPane
            tab={t('dashboard.articlePage.tabs.buyRecords')}
            key='buyers'
          >
            <ArticleOrdersComponent uuid={uuid} orderType='buy_article' />
          </Tabs.TabPane>
          <Tabs.TabPane
            tab={t('dashboard.articlePage.tabs.rewardRecords')}
            key='rewarders'
          >
            <ArticleOrdersComponent uuid={uuid} orderType='reward_article' />
          </Tabs.TabPane>
          <Tabs.TabPane
            tab={t('dashboard.articlePage.tabs.commentRecords')}
            key='comments'
          >
            <ArticleCommentsComponent articleId={article.id} />
          </Tabs.TabPane>
        </Tabs>
      </div>
    </div>
  );
}
