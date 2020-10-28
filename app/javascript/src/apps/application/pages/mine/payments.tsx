import {
  MyPaymentConnectionQueryHookResult,
  Payment,
  useMyPaymentConnectionQuery,
} from '@graphql';
import { Avatar, Button, Col, List, Row } from 'antd';
import moment from 'moment';
import React from 'react';
import { useHistory } from 'react-router-dom';
import { Loading } from '../../components';
import { PRS_ICON_URL } from '../../shared';

export function Payments() {
  const history = useHistory();
  const {
    data,
    loading,
    fetchMore,
  }: MyPaymentConnectionQueryHookResult = useMyPaymentConnectionQuery();

  if (loading) {
    return <Loading />;
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
            <Col>
              <Avatar src={PRS_ICON_URL} />
            </Col>
            <Col>{payment.amount}</Col>
            <Col>
              {
                {
                  paid: '已支付',
                  refunded: '已退款',
                  completed: '已完成',
                }[payment.state]
              }
            </Col>
            <Col>
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
