import LoadingComponent from '@dashboard/components/LoadingComponent/LoadingComponent';
import { useMyStatisticsQuery } from '@graphql';
import { useCurrentUser } from '@shared';
import { Col, PageHeader, Row, Statistic, Tooltip } from 'antd';
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
      <PageHeader title={t('dashboard.menu.overview')} />
      <Row gutter={16} style={{ textAlign: 'center' }}>
        <Col xs={12} sm={6}>
          <Statistic
            title={t('user.articlesCount')}
            value={currentUser.statistics.articlesCount}
          />
        </Col>
        <Col xs={12} sm={6}>
          <Statistic
            title={t('user.boughtArticlesCount')}
            value={currentUser.statistics.boughtArticlesCount}
          />
        </Col>
      </Row>
      <Row gutter={16} style={{ textAlign: 'center' }}>
        <Tooltip title={t('dashboard.overviewPage.presentValue')}>
          <Col xs={12} sm={6}>
            <Statistic
              title={t('user.authorRevenueTotal')}
              value={currentUser.statistics.authorRevenueTotalUsd.toFixed(2)}
            />
          </Col>
        </Tooltip>
        <Tooltip title={t('dashboard.overviewPage.presentValue')}>
          <Col xs={12} sm={6}>
            <Statistic
              title={t('user.readerRevenueTotal')}
              value={currentUser.statistics.readerRevenueTotalUsd.toFixed(2)}
            />
          </Col>
        </Tooltip>
        <Tooltip title={t('dashboard.overviewPage.perPriceWhenPaid')}>
          <Col xs={12} sm={6}>
            <Statistic
              title={t('user.paymentTotalUsd')}
              value={currentUser.statistics.paymentTotalUsd.toFixed(2)}
            />
          </Col>
        </Tooltip>
      </Row>
    </div>
  );
}
