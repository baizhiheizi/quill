import { PageHeader } from 'antd';
import SwapOrdersComponent from 'apps/admin/components/SwapOrdersComponent/SwapOrdersCompnent';
import React from 'react';

export default function SwapOrdersPage() {
  return (
    <>
      <PageHeader title='Swap Orders' />
      <SwapOrdersComponent />
    </>
  );
}
