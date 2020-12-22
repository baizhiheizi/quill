import { updateActiveMenu } from '@dashboard/shared';
import { PageHeader, Tabs } from 'antd';
import React from 'react';
import { useTranslation } from 'react-i18next';
import MyTransfersComponent from './components/MyTranfersComponent';

export default function RevenuePage() {
  updateActiveMenu('revenue');
  const { t } = useTranslation();
  return (
    <div>
      <PageHeader title={t('dashboard.menu.revenue')} />
      <Tabs>
        <Tabs.TabPane
          tab={t('dashboard.revenuePage.authorTransfers')}
          key='author'
        >
          <MyTransfersComponent transferType='author_revenue' />
        </Tabs.TabPane>
        <Tabs.TabPane
          tab={t('dashboard.revenuePage.readerTransfers')}
          key='reader'
        >
          <MyTransfersComponent transferType='reader_revenue' />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
