import {
  MyTransferConnectionQueryHookResult,
  Transfer,
  useMyTransferConnectionQuery,
} from '@graphql';
import { Avatar, Button, Col, List, Row } from 'antd';
import React from 'react';
import { Loading } from '../../components';
import { PRS_ICON_URL } from '../../shared';

export function Transfers() {
  const {
    data,
    loading,
    fetchMore,
  }: MyTransferConnectionQueryHookResult = useMyTransferConnectionQuery();

  if (loading) {
    return <Loading />;
  }

  const {
    myTransferConnection: {
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
                    const connection = fetchMoreResult.myTransferConnection;
                    connection.nodes = prev.myTransferConnection.nodes.concat(
                      connection.nodes,
                    );
                    return Object.assign({}, prev, {
                      myTransferConnection: connection,
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
            <Col>
              <Avatar src={PRS_ICON_URL} />
            </Col>
            <Col>{transfer.amount}</Col>
            <Col>
              {
                {
                  payment_refund: '退款',
                  buy_article: '购买文章',
                  reward_article: '打赏文章',
                }[transfer.transferType]
              }
            </Col>
            <Col>
              {transfer.snapshotId ? (
                <a
                  href={`https://mixin.one/snapshots/${transfer.snapshotId}`}
                  target='_blank'
                >
                  链上快照
                </a>
              ) : (
                <span>待处理</span>
              )}
            </Col>
          </Row>
        </List.Item>
      )}
    />
  );
}
