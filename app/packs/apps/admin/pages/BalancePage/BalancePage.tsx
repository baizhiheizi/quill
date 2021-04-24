import WalletBalanceComponent from '@admin/components/WalletBalanceComponent/WalletBalanceComponent';
import { PageHeader } from 'antd';
import React from 'react';

export default function BalancePage() {
  return (
    <div>
      <PageHeader title='Balance' />
      <WalletBalanceComponent />
    </div>
  );
}
