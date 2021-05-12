import { Button, Typography } from 'antd';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function LoadMoreComponent(props: {
  hasNextPage: boolean;
  loading: boolean;
  fetchMore: (params: any) => any;
}) {
  const { t } = useTranslation();
  const { hasNextPage, loading, fetchMore } = props;
  return (
    <div
      style={{
        textAlign: 'center',
        marginTop: 12,
        height: 32,
        lineHeight: '32px',
      }}
    >
      {hasNextPage ? (
        <Button loading={loading} onClick={fetchMore}>
          {t('load_more')}
        </Button>
      ) : (
        <Typography.Text type='secondary'> - END -</Typography.Text>
      )}
    </div>
  );
}
