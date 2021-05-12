import { Avatar, Button, Col, List, Row, Space, Tag } from 'antd';
import LoadingComponent from 'apps/dashboard/components/LoadingComponent/LoadingComponent';
import { SwapOrder, useMySwapOrderConnectionQuery } from 'graphqlTypes';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function MySwapOrderComponent() {
  const { t } = useTranslation();

  const { loading, data, fetchMore } = useMySwapOrderConnectionQuery();

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    mySwapOrderConnection: {
      nodes: swapOrders,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  return (
    <List
      size='small'
      itemLayout='vertical'
      dataSource={swapOrders}
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
              {t('load_more')}
            </Button>
          </div>
        )
      }
      renderItem={(swapOrder: Partial<SwapOrder>) => (
        <List.Item key={swapOrder.traceId}>
          <Row align='middle'>
            <Col xs={6} sm={6} md={6}>
              <Tag
                color={
                  swapOrder.state === 'completed'
                    ? 'green'
                    : swapOrder.state === 'rejected'
                    ? 'volcano'
                    : swapOrder.state === 'refunded'
                    ? 'volcano'
                    : 'blue'
                }
              >
                {t(`swap_order.state.${swapOrder.state}`)}
              </Tag>
            </Col>
            <Col xs={18} sm={18} md={12} style={{ overflowX: 'scroll' }}>
              <Space>
                <Avatar src={swapOrder.payAsset.iconUrl} />
                <span>{swapOrder.funds}</span>
                <span style={{ color: '#aaa' }}>to</span>
                <Avatar src={swapOrder.fillAsset.iconUrl} />
                <span>{swapOrder.amount || '?'}</span>
              </Space>
            </Col>
            <Col xs={0} sm={0} md={6}>
              {moment(swapOrder.createdAt).format('YYYY-MM-DD HH:mm:SS')}
            </Col>
          </Row>
        </List.Item>
      )}
    />
  );
}
