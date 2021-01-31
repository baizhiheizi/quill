import TransfersComponent from '@admin/components/TransfersComponent/TransfersComponent';
import { PageHeader } from 'antd';
import React from 'react';

export default function TransfersPage() {
  return (
    <div>
      <PageHeader title='Transfers' />
      <TransfersComponent />
    </div>
  );
}
