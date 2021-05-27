import { PageHeader } from 'antd';
import { PrsTransactionsComponent } from 'apps/admin/components/PrsTransactionsComponent/PrsTransactionsComponent';
import React from 'react';

export default function PrsTransactionsPage() {
  return (
    <>
      <PageHeader title='Prs Transactions' />
      <PrsTransactionsComponent />
    </>
  );
}
