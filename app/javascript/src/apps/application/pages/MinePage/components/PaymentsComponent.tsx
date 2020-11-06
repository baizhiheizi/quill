import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import { PRS_ICON_URL } from '@application/shared';
import {
  MyPaymentConnectionQueryHookResult,
  Payment,
  useMyPaymentConnectionQuery,
} from '@graphql';
import { Avatar, Button, Col, List, Row } from 'antd';
import moment from 'moment';
import React from 'react';
moment.locale('zh-cn');

export default function PaymentsComponent() {
  const {
    data,
    loading,
    fetchMore,
  }: MyPaymentConnectionQueryHookResult = useMyPaymentConnectionQuery();

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    myPaymentConnection: {
      nodes: payments,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  return (
    <List
      size='small'
      itemLayout='vertical'
      dataSource={payments}
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
                    const connection = fetchMoreResult.myPaymentConnection;
                    connection.nodes = prev.myPaymentConnection.nodes.concat(
                      connection.nodes,
                    );
                    return Object.assign({}, prev, {
                      myPaymentConnection: connection,
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
      renderItem={(payment: Partial<Payment>) => (
        <List.Item key={payment.traceId}>
          <Row justify='space-around'>
            <Col xs={4} sm={4} md={2}>
              <Avatar src={PRS_ICON_URL} />
            </Col>
            <Col xs={0} sm={0} md={8}>
              {moment(payment.createdAt).format('YYYY-MM-DD HH:mm:SS')}
            </Col>
            <Col xs={8} sm={8} md={6}>
              {payment.amount}
            </Col>
            <Col xs={6} sm={6} md={4}>
              {
                {
                  paid: '已支付',
                  refunded: '已退款',
                  completed: '已完成',
                }[payment.state]
              }
            </Col>
            <Col xs={6} sm={6} md={4}>
              <a
                href={`https://mixin.one/snapshots/${payment.snapshotId}`}
                target='_blank'
              >
                链上快照
              </a>
            </Col>
          </Row>
        </List.Item>
      )}
    />
  );
}
