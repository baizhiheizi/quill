import {
  StatisticsQueryHookResult,
  Transfer,
  useRevenueChartQuery,
  useStatisticsQuery,
  useTransferConnectionQuery,
} from '@graphql';
import { Avatar, Button, Col, List, Row, Statistic, Tabs, Tag } from 'antd';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import LoadingComponent from '../../components/LoadingComponent/LoadingComponent';
import { PRS_ICON_URL } from '../../shared';

export default function FairPage() {
  const { t } = useTranslation();
  const { data, loading }: StatisticsQueryHookResult = useStatisticsQuery();

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
      <Row
        style={{ padding: 20, textAlign: 'center' }}
        gutter={16}
        justify='space-around'
      >
        <Col span={12}>
          <Statistic title={t('fairPage.usersCount')} value={usersCount} />
        </Col>
        <Col span={12}>
          <Statistic
            title={t('fairPage.articlesCount')}
            value={articlesCount}
          />
        </Col>
        <Col span={12}>
          <Statistic
            title={t('fairPage.authorRevenueAmount')}
            value={Math.floor(authorRevenueAmount)}
          />
        </Col>
        <Col span={12}>
          <Statistic
            title={t('fairPage.readerRevenueAmount')}
            value={Math.floor(readerRevenueAmount)}
          />
        </Col>
      </Row>
      <Tabs defaultActiveKey='revenue'>
        <Tabs.TabPane tab={t('fairPage.tabs.revenue.title')} key='revenue'>
          <PrsdiggRevenueChart />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('fairPage.tabs.transfers.title')} key='transfers'>
          <TransferList />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}

function PrsdiggRevenueChart() {
  const { data, loading } = useRevenueChartQuery();
  const { t } = useTranslation();
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
      <h3>{t('fairPage.tabs.revenue.chartTitle')}</h3>
      <ResponsiveContainer height={250}>
        <AreaChart
          data={revenueChart}
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
    </div>
  );
}

function TransferList() {
  const { t } = useTranslation();
  const { data, loading, fetchMore } = useTransferConnectionQuery();

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    transferConnection: {
      nodes: transfers,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  return (
    <List
      size='small'
      itemLayout='vertical'
      dataSource={transfers}
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
                  },
                });
              }}
            >
              {t('common.loadMore')}
            </Button>
          </div>
        )
      }
      renderItem={(transfer: Partial<Transfer>) => (
        <List.Item key={transfer.traceId}>
          <Row justify='space-around'>
            <Col xs={4} sm={4} md={2}>
              <Avatar size='small' src={PRS_ICON_URL} />
            </Col>
            <Col xs={0} sm={0} md={8}>
              {moment(transfer.createdAt).format('YYYY-MM-DD HH:mm:SS')}
            </Col>
            <Col xs={8} sm={8} md={6}>
              {transfer.amount}
            </Col>
            <Col xs={6} sm={6} md={4}>
              <Tag
                color={
                  transfer.transferType === 'payment_refund'
                    ? 'magenta'
                    : transfer.transferType === 'author_revenue'
                    ? 'green'
                    : 'cyan'
                }
              >
                {t(`transfer.transferType.${transfer.transferType}`)}
              </Tag>
            </Col>
            <Col xs={6} sm={6} md={4}>
              {transfer.snapshotId ? (
                <a
                  href={`https://mixin.one/snapshots/${transfer.snapshotId}`}
                  target='_blank'
                >
                  {t('transfer.snapshot')}
                </a>
              ) : (
                <span>{t('transfer.processing')}</span>
              )}
            </Col>
          </Row>
        </List.Item>
      )}
    />
  );
}
