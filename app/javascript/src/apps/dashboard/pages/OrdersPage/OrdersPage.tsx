import { updateActiveMenu } from '@dashboard/shared';
import { PageHeader, Tabs } from 'antd';
import React from 'react';
import { useTranslation } from 'react-i18next';
import MyPaymentsComponent from './components/MyPaymentsComponent';
import MySwapOrderComponent from './components/MySwapOrdersComponent';

export default function OrdersPage() {
  updateActiveMenu('orders');
  const { t } = useTranslation();

  return (
    <div>
      <PageHeader title={t('dashboard.menu.orders')} />
      <Tabs>
        <Tabs.TabPane
          tab={t('dashboard.ordersPage.tabs.payments')}
          key='payments'
        >
          <MyPaymentsComponent />
        </Tabs.TabPane>
        <Tabs.TabPane
          tab={t('dashboard.ordersPage.tabs.swapOrders')}
          key='swapOrders'
        >
          <MySwapOrderComponent />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
