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
import { useTranslation } from 'react-i18next';

export default function MyPaymentsComponent() {
  const { t, i18n } = useTranslation();
  moment.locale(i18n.language);
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
              {t(`payment.state.${payment.state}`, '-')}
            </Col>
            <Col xs={6} sm={6} md={4}>
              <a
                href={`https://mixin.one/snapshots/${payment.snapshotId}`}
                target='_blank'
              >
                {t('payment.snapshot')}
              </a>
            </Col>
          </Row>
        </List.Item>
      )}
    />
  );
}
