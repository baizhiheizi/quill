import { useUserAgent } from '@shared';
import { Button, List } from 'antd';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function ListComponent(props: {
  dataSource: any;
  hasNextPage: boolean;
  loading: boolean;
  fetchMore: () => any;
  renderItem: any;
}) {
  const { isMobile } = useUserAgent();
  const { t } = useTranslation();
  const { dataSource, hasNextPage, loading, fetchMore, renderItem } = props;
  return (
    <List
      size='small'
      dataSource={dataSource}
      itemLayout={isMobile.phone ? 'vertical' : 'horizontal'}
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
            <Button loading={loading} onClick={fetchMore}>
              {t('common.loadMore')}
            </Button>
          </div>
        )
      }
      renderItem={renderItem}
    />
  );
}
