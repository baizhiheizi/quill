import { PageHeader } from 'antd';
import DailyStatisticsComponent from 'apps/admin/components/DailyStatisticsComponent/DailyStatisticsComponent';
import React from 'react';

export default function DailyStatisticsPage() {
  return (
    <>
      <PageHeader title='Daily Statistic' />
      <DailyStatisticsComponent />
    </>
  );
}
