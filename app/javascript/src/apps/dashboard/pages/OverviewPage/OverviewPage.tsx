import LoadingComponent from '@dashboard/components/LoadingComponent/LoadingComponent';
import { updateActiveMenu } from '@dashboard/shared';
import { useMyStatisticsQuery } from '@graphql';
import { useCurrentUser } from '@shared';
import { Col, PageHeader, Row, Statistic } from 'antd';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function OverviewPage() {
  updateActiveMenu('overview');
  const currentUser = useCurrentUser();
  const { t } = useTranslation();
  const { loading, data } = useMyStatisticsQuery();

  if (loading) {
    return <LoadingComponent />;
  }

  currentUser.statistics = data.myStatistics;

  return (
    <div>
      <PageHeader title='Overview' />
      <Row gutter={16} style={{ textAlign: 'center' }}>
        <Col xs={12} sm={6}>
          <Statistic
            title={t('user.articlesCount')}
            value={currentUser.statistics.articlesCount}
          />
        </Col>
        <Col xs={12} sm={6}>
          <Statistic
            title={t('user.authorRevenueAmount')}
            value={currentUser.statistics.authorRevenueAmount}
          />
        </Col>
        <Col xs={12} sm={6}>
          <Statistic
            title={t('user.boughtArticlesCount')}
            value={currentUser.statistics.boughtArticlesCount}
          />
        </Col>
        <Col xs={12} sm={6}>
          <Statistic
            title={t('user.readerRevenueAmount')}
            value={currentUser.statistics.readerRevenueAmount}
          />
        </Col>
      </Row>
    </div>
  );
}
