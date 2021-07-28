import { Avatar, Button, Descriptions, PageHeader, Tabs, Tag } from 'antd';
import LoadingComponent from 'apps/dashboard/components/LoadingComponent/LoadingComponent';
import { useMyArticleQuery } from 'graphqlTypes';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useHistory, useParams } from 'react-router-dom';
import ArticleCommentsComponent from './components/ArticleCommentsComponent';
import ArticleOrdersComponent from './components/ArticleOrdersComponent';

export default function ArticlePage() {
  const { t, i18n } = useTranslation();
  const history = useHistory();
  moment.locale(i18n.language);
  const { uuid } = useParams<{ uuid: string }>();
  const { loading, data } = useMyArticleQuery({
    variables: { uuid },
    fetchPolicy: 'network-only',
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const { myArticle: article } = data;

  if (article.state === 'drafted') {
    history.replace(`/articles/${article.uuid}/edit`);
    return <LoadingComponent />;
  }

  return (
    <div>
      <PageHeader
        title={t('article_detail')}
        extra={[
          <Button key='edit' type='primary'>
            <Link to={`/articles/${uuid}/edit`}>{t('edit')}</Link>
          </Button>,
          <Button key='view'>
            <a href={`/articles/${uuid}`} target='_blank'>
              {t('view')}
            </a>
          </Button>,
        ]}
        breadcrumb={{
          routes: [
            { path: '/articles', breadcrumbName: t('articles_manage') },
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
          <Descriptions.Item label={t('article.state_text')}>
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
          <Descriptions.Item label={t('article.created_at')}>
            {moment(article.createdAt).format('YYYY-MM-DD HH:mm:ss')}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.updated_at')}>
            {moment(article.updatedAt).format('YYYY-MM-DD HH:mm:ss')}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.price')}>
            {article.price} {article.currency.symbol}
          </Descriptions.Item>
          <Descriptions.Item label={t('readers_revenue')}>
            {article.readersRevenueRatio * 100}%
          </Descriptions.Item>
          <Descriptions.Item label={t('platform_revenue')}>
            {article.platformRevenueRatio * 100}%
          </Descriptions.Item>
          <Descriptions.Item label={t('author_revenue')}>
            {article.authorRevenueRatio * 100}%
          </Descriptions.Item>
          <Descriptions.Item label={t('references_revenue')}>
            {article.referencesRevenueRatio * 100}%
          </Descriptions.Item>
          <Descriptions.Item label={t('article.buy_orders_count')}>
            {article.buyOrders.totalCount}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.reward_orders_count')}>
            {article.rewardOrders.totalCount}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.revenue')}>
            ${article.revenueUsd.toFixed(4)}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.author_revenue_total')}>
            ${article.authorRevenueUsd.toFixed(4)}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.reader_revenue_total')}>
            ${article.readerRevenueUsd.toFixed(4)}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.comments_count')}>
            {article.comments.totalCount}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.upvotes_count')}>
            {article.upvotesCount}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.downvotes_count')}>
            {article.downvotesCount}
          </Descriptions.Item>
          <Descriptions.Item label={t('article.tags')}>
            {article.tagNames.length > 0
              ? article.tagNames.map((tagName: string) => (
                  <Tag key={tagName}>#{tagName}</Tag>
                ))
              : '-'}
          </Descriptions.Item>
          <Descriptions.Item label={t('article_references')}>
            {article.articleReferences.length > 0
              ? article.articleReferences.map((articleReference) => (
                  <div
                    key={articleReference.reference.uuid}
                    className='flex flex-wrap items-center py-1'
                  >
                    <Avatar
                      className='mr-2'
                      size='small'
                      src={articleReference.reference.author.avatar}
                    />
                    <span className='mr-2'>
                      {articleReference.reference.author.name}:
                    </span>
                    <a
                      href={`/articles/${articleReference.reference.uuid}`}
                      target='_blank'
                    >
                      {articleReference.reference.title}
                    </a>
                    <div className='ml-auto text-blue-500'>
                      {articleReference.revenueRatio * 100}%
                    </div>
                  </div>
                ))
              : '-'}
          </Descriptions.Item>
        </Descriptions>
      </div>
      <div>
        <Tabs>
          <Tabs.TabPane tab={t('buy_records')} key='buyers'>
            <ArticleOrdersComponent uuid={uuid} orderType='buy_article' />
          </Tabs.TabPane>
          <Tabs.TabPane tab={t('reward_records')} key='rewarders'>
            <ArticleOrdersComponent uuid={uuid} orderType='reward_article' />
          </Tabs.TabPane>
          <Tabs.TabPane tab={t('cite_records')} key='citers'>
            <ArticleOrdersComponent uuid={uuid} orderType='cite_article' />
          </Tabs.TabPane>
          <Tabs.TabPane tab={t('comment_records')} key='comments'>
            <ArticleCommentsComponent articleId={article.id} />
          </Tabs.TabPane>
        </Tabs>
      </div>
    </div>
  );
}
