import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import { PRS_ICON_URL } from '@application/shared';
import {
  MyTransferConnectionQueryHookResult,
  Transfer,
  useMyTransferConnectionQuery,
} from '@graphql';
import { Avatar, Button, Col, List, Row } from 'antd';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function MyTransfersComponent() {
  const { t, i18n } = useTranslation();
  moment.locale(i18n.language);
  const {
    data,
    loading,
    fetchMore,
  }: MyTransferConnectionQueryHookResult = useMyTransferConnectionQuery();

  if (loading) {
    return <LoadingComponent />;
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
              <Avatar src={PRS_ICON_URL} />
            </Col>
            <Col xs={0} sm={0} md={8}>
              {moment(transfer.createdAt).format('YYYY-MM-DD HH:mm:SS')}
            </Col>
            <Col xs={8} sm={8} md={6}>
              {transfer.amount}
            </Col>
            <Col xs={6} sm={6} md={4}>
              {t(`transfer.transferType.${transfer.transferType}`)}
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
