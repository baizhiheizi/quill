import {
  StatisticsQueryHookResult,
  Transfer,
  useRevenueChartQuery,
  useStatisticsQuery,
  useTransferConnectionQuery,
} from '@/graphql';
import { Avatar, Button, Col, List, Row, Statistic, Tabs, Tag } from 'antd';
import moment from 'moment';
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
import LoadingComponent from '../../components/LoadingComponent/LoadingComponent';
import { PRS_ICON_URL } from '../../shared';

export default function FairPage() {
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
          <Statistic title='用户总量' value={usersCount} />
        </Col>
        <Col span={12}>
          <Statistic title='文章总数' value={articlesCount} />
        </Col>
        <Col span={12}>
          <Statistic title='作者收益(PRS)' value={authorRevenueAmount} />
        </Col>
        <Col span={12}>
          <Statistic title='读者收益(PRS)' value={readerRevenueAmount} />
        </Col>
      </Row>
      <Tabs defaultActiveKey='revenue'>
        <Tabs.TabPane tab='平台收益' key='revenue'>
          <PrsdiggRevenueChart />
        </Tabs.TabPane>
        <Tabs.TabPane tab='转账记录' key='transfers'>
          <TransferList />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}

function PrsdiggRevenueChart() {
  const { data, loading } = useRevenueChartQuery();
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
      <h3>平台收益曲线</h3>
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
                  updateQuery: (prev, { fetchMoreResult }) => {
                    if (!fetchMoreResult) {
                      return prev;
                    }
                    const connection = fetchMoreResult.transferConnection;
                    connection.nodes = prev.transferConnection.nodes.concat(
                      connection.nodes,
                    );
                    return Object.assign({}, prev, {
                      transferConnection: connection,
                    });
                  },
                  variables: {
                    after: endCursor,
                  },
                });
              }}
            >
              加载更多
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
              {transfer.transferType === 'payment_refund' && (
                <Tag color='magenta'>原路返回</Tag>
              )}
              {transfer.transferType === 'author_revenue' && (
                <Tag color='green'>作者收益</Tag>
              )}
              {transfer.transferType === 'reader_revenue' && (
                <Tag color='cyan'>读者收益</Tag>
              )}
            </Col>
            <Col xs={6} sm={6} md={4}>
              {transfer.snapshotId ? (
                <a
                  href={`https://mixin.one/snapshots/${transfer.snapshotId}`}
                  target='_blank'
                >
                  链上快照
                </a>
              ) : (
                <span>等待处理</span>
              )}
            </Col>
          </Row>
        </List.Item>
      )}
    />
  );
}
