import { Col, PageHeader, Row, Statistic, Tooltip } from 'antd';
import LoadingComponent from 'apps/dashboard/components/LoadingComponent/LoadingComponent';
import { useCurrentUser } from 'apps/shared';
import { useMyStatisticsQuery } from 'graphqlTypes';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function OverviewPage() {
  const { currentUser } = useCurrentUser();
  const { t } = useTranslation();
  const { loading, data } = useMyStatisticsQuery();

  if (loading) {
    return <LoadingComponent />;
  }

  currentUser.statistics = data.myStatistics;

  return (
    <div>
      <PageHeader title={t('overview')} />
      <Row gutter={16} style={{ textAlign: 'center' }}>
        <Col xs={12} sm={6}>
          <Statistic
            title={t('user.articles_count')}
            value={currentUser.statistics.articlesCount}
          />
        </Col>
        <Col xs={12} sm={6}>
          <Statistic
            title={t('user.bought_articles_count')}
            value={currentUser.statistics.boughtArticlesCount}
          />
        </Col>
      </Row>
      <Row gutter={16} style={{ textAlign: 'center' }}>
        <Tooltip title={t('present_value')}>
          <Col xs={12} sm={6}>
            <Statistic
              title={t('user.author_revenue_total')}
              value={currentUser.statistics.authorRevenueTotalUsd.toFixed(2)}
            />
          </Col>
        </Tooltip>
        <Tooltip title={t('present_value')}>
          <Col xs={12} sm={6}>
            <Statistic
              title={t('user.reader_revenue_total')}
              value={currentUser.statistics.readerRevenueTotalUsd.toFixed(2)}
            />
          </Col>
        </Tooltip>
        <Tooltip title={t('per_price_when_paid')}>
          <Col xs={12} sm={6}>
            <Statistic
              title={t('user.payment_total_usd')}
              value={currentUser.statistics.paymentTotalUsd.toFixed(2)}
            />
          </Col>
        </Tooltip>
      </Row>
    </div>
  );
}
