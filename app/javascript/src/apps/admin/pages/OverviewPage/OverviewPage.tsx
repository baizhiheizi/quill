import {
  useArticleChartQuery,
  useRevenueChartQuery,
  useStatisticsQuery,
  useUserChartQuery,
} from '@/graphql';
import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import { Col, PageHeader, Row, Statistic } from 'antd';
import React from 'react';
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

export default function OverviewPage() {
  const { data, loading } = useStatisticsQuery();

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    statistics: {
      usersCount,
      articlesCount,
      authorRevenueAmount,
      readerRevenueAmount,
    },
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
      <UserChart />
      <ArticleChart />
      <RevenueChart />
    </div>
  );
}

function UserChart() {
  const { loading, data } = useUserChartQuery();
  if (loading) {
    return <LoadingComponent />;
  }

  let { userChart } = data;
  try {
    userChart = JSON.parse(userChart);
  } catch {
    userChart = [];
  }

  return (
    <div>
      <h3>User Chart</h3>
      <AreaChartComponent data={userChart} />
    </div>
  );
}

function ArticleChart() {
  const { loading, data } = useArticleChartQuery();
  if (loading) {
    return <LoadingComponent />;
  }

  let { articleChart } = data;
  try {
    articleChart = JSON.parse(articleChart);
  } catch {
    articleChart = [];
  }

  return (
    <div>
      <h3>Article Chart</h3>
      <AreaChartComponent data={articleChart} />
    </div>
  );
}

function RevenueChart() {
  const { loading, data } = useRevenueChartQuery();
  if (loading) {
    return <LoadingComponent />;
  }

  let { revenueChart } = data;
  try {
    revenueChart = JSON.parse(revenueChart);
  } catch {
    revenueChart = [];
  }

  return (
    <div>
      <h3>Revenue Chart</h3>
      <AreaChartComponent data={revenueChart} />
    </div>
  );
}

function AreaChartComponent(props: { data: any }) {
  return (
    <ResponsiveContainer height={250}>
      <AreaChart
        data={props.data}
        margin={{ top: 10, right: 30, left: 0, bottom: 0 }}
      >
        <defs>
          <linearGradient id='colorUser' x1='0' y1='0' x2='0' y2='1'>
            <stop offset='5%' stopColor='#8884d8' stopOpacity={0.8} />
            <stop offset='95%' stopColor='#8884d8' stopOpacity={0} />
          </linearGradient>
        </defs>
        <XAxis dataKey='name' />
        <YAxis />
        <CartesianGrid strokeDasharray='3 3' />
        <Tooltip />
        <Area
          type='monotone'
          dataKey='value'
          stroke='#8884d8'
          fillOpacity={1}
          fill='url(#colorUser)'
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
