import { SUPPORTED_TOKENS } from '@shared';
import LoadingComponent from '@dashboard/components/LoadingComponent/LoadingComponent';
import {
  Payment,
  SwapOrder,
  useMyPaymentConnectionQuery,
  useMySwapOrderConnectionQuery,
} from '@graphql';
import { Avatar, Button, Col, List, Row, Space, Tag } from 'antd';
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
              {t('common.loadMore')}
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
                {t(`swapOrder.state.${swapOrder.state}`)}
              </Tag>
            </Col>
            <Col xs={18} sm={18} md={12} style={{ overflowX: 'scroll' }}>
              <Space>
                <Avatar
                  src={
                    SUPPORTED_TOKENS.find(
                      (token) => token.assetId === swapOrder.payAssetId,
                    )?.iconUrl
                  }
                />
                <span>{swapOrder.funds}</span>
                <span style={{ color: '#aaa' }}>to</span>
                <Avatar
                  src={
                    SUPPORTED_TOKENS.find(
                      (token) => token.assetId === swapOrder.fillAssetId,
                    )?.iconUrl
                  }
                />
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
