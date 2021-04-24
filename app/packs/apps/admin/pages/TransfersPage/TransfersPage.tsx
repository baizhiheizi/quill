import { PageHeader } from 'antd';
import TransfersComponent from 'apps/admin/components/TransfersComponent/TransfersComponent';
import React from 'react';

export default function TransfersPage() {
  return (
    <div>
      <PageHeader title='Transfers' />
      <TransfersComponent />
    </div>
  );
}
