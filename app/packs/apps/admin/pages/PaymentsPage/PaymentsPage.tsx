import { PageHeader } from 'antd';
import PaymentsComponent from 'apps/admin/components/PaymentsComponent/PaymentsComponent';
import React from 'react';

export default function PaymentsPage() {
  return (
    <>
      <PageHeader title='Payments' />
      <PaymentsComponent />
    </>
  );
}
