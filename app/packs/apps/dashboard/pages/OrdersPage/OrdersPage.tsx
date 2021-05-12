import { PageHeader, Tabs } from 'antd';
import React from 'react';
import { useTranslation } from 'react-i18next';
import MyPaymentsComponent from './components/MyPaymentsComponent';
import MySwapOrderComponent from './components/MySwapOrdersComponent';

export default function OrdersPage() {
  const { t } = useTranslation();

  return (
    <div>
      <PageHeader title={t('orders_manage')} />
      <Tabs>
        <Tabs.TabPane tab={t('payments')} key='payments'>
          <MyPaymentsComponent />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('swap_orders')} key='swapOrders'>
          <MySwapOrderComponent />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
