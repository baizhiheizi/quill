import {
  StatisticsQueryHookResult,
  Transfer,
  useStatisticsQuery,
  useTransferConnectionQuery,
} from '@/graphql';
import { Avatar, Button, Col, List, Row, Statistic } from 'antd';
import moment from 'moment';
import React from 'react';
import { Loading } from '../../components';
import { PRS_ICON_URL } from '../../shared';

export function Fair() {
  const {
    data: statisticsData,
    loading: statisticsLoading,
  }: StatisticsQueryHookResult = useStatisticsQuery();
  const { data, loading, fetchMore } = useTransferConnectionQuery();

  if (statisticsLoading || loading) {
    return <Loading />;
  }

  const {
    statistics: {
      usersCount,
      articlesCount,
      authorRevenueAmount,
      readerRevenueAmount,
    },
  } = statisticsData;
  const {
    transferConnection: {
      nodes: transfers,
      pageInfo: { hasNextPage, endCursor },
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
          <Statistic title='作者收益' value={authorRevenueAmount} />
        </Col>
        <Col span={12}>
          <Statistic title='读者收益' value={readerRevenueAmount} />
        </Col>
      </Row>
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
              <Col xs={6} sm={6} md={4}>
                <Avatar size='small' src={PRS_ICON_URL} />
              </Col>
              <Col xs={0} sm={0} md={8}>
                {moment(transfer.createdAt).format('YYYY-MM-DD HH:mm:SS')}
              </Col>
              <Col xs={6} sm={6} md={4}>
                {transfer.amount}
              </Col>
              <Col xs={6} sm={6} md={4}>
                {
                  {
                    payment_refund: '退款',
                    author_revenue: '作者收益',
                    reader_revenue: '读者收益',
                  }[transfer.transferType]
                }
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
    </div>
  );
}
