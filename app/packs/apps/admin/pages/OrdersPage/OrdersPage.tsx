import { PageHeader } from 'antd';
import OrdersComponent from 'apps/admin/components/OrdersComponent/OrdersComponent';
import React from 'react';

export default function OrdersPage() {
  return (
    <>
      <PageHeader title='Orders' />
      <OrdersComponent />
    </>
  );
}
