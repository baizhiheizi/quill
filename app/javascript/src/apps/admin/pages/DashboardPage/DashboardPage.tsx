import { useStatisticsQuery } from '@/graphql';
import { Col, PageHeader, Row, Statistic } from 'antd';
import React from 'react';
import LoadingComponent from '../../components/LoadingComponent/LoadingComponent';

export default function DashboardPage() {
  const { data, loading } = useStatisticsQuery();

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    usersCount,
    articlesCount,
    authorRevenueAmount,
    readerRevenueAmount,
  } = data;

  return (
    <div>
      <PageHeader title='Dashboard' />
      <Row
        style={{ padding: 20, textAlign: 'center' }}
        gutter={16}
        justify='space-around'
      >
        <Col span={12}>
          <Statistic title='用户总量' value={usersCount} />
        </Col>
        <Col span={12}>
          <Statistic title='文章总数' value={articlesCount} />
        </Col>
        <Col span={12}>
          <Statistic title='作者收益' value={authorRevenueAmount} />
        </Col>
        <Col span={12}>
          <Statistic title='读者收益' value={readerRevenueAmount} />
        </Col>
      </Row>
    </div>
  );
}
