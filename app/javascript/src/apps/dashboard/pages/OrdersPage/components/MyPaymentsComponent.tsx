import { SUPPORTED_TOKENS } from '@shared';
import LoadingComponent from '@dashboard/components/LoadingComponent/LoadingComponent';
import { Payment, useMyPaymentConnectionQuery } from '@graphql';
import { Avatar, Button, Col, List, Row, Tag } from 'antd';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function MyPaymentsComponent() {
  const { t } = useTranslation();
  const { loading, data, fetchMore } = useMyPaymentConnectionQuery({});

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
      renderItem={(payment: Partial<Payment>) => (
        <List.Item key={payment.traceId}>
          <Row align='middle'>
            <Col xs={6} sm={6} md={6}>
              <Tag
                color={
                  payment.state === 'completed'
                    ? 'green'
                    : payment.state === 'paid'
                    ? 'blue'
                    : 'volcano'
                }
              >
                {t(`payment.state.${payment.state}`)}
              </Tag>
            </Col>
            <Col xs={4} sm={4} md={3}>
              <Avatar
                src={
                  SUPPORTED_TOKENS.find(
                    (token) => token.assetId === payment.assetId,
                  )?.iconUrl
                }
              />
            </Col>
            <Col xs={8} sm={8} md={6}>
              {payment.amount}
            </Col>
            <Col xs={0} sm={0} md={6}>
              {moment(payment.createdAt).format('YYYY-MM-DD HH:mm:SS')}
            </Col>
            <Col xs={6} sm={6} md={3}>
              <a
                href={`https://mixin.one/snapshots/${payment.snapshotId}`}
                target='_blank'
              >
                {t('payment.snapshot')}
              </a>
            </Col>
          </Row>
          {payment.order && (
            <Row>
              <a
                style={{ color: '#aaa' }}
                href={`/articles/${payment.order.item.uuid}`}
                target='_blank'
              >
                {payment.order.item.title}
              </a>
            </Row>
          )}
        </List.Item>
      )}
    />
  );
}
