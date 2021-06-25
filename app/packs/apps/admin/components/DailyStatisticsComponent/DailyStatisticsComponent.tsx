import { Button, Table, DatePicker } from 'antd';
import { ColumnProps } from 'antd/es/table';
import LoadingComponent from 'apps/admin/components/LoadingComponent/LoadingComponent';
import {
  DailyStatistic as IDailyStatistic,
  useAdminDailyStatisticConnectionQuery,
} from 'graphqlTypes';
import React, { useState } from 'react';
import moment from 'moment';

export default function DailyStatisticsComponent() {
  const [startDate, setStartDate] = useState(
    moment().startOf('day').subtract(7, 'day').format('YYYY-MM-DD'),
  );
  const [endDate, setEndDate] = useState(
    moment().endOf('day').subtract(1, 'day').format('YYYY-MM-DD'),
  );

  const { data, loading, fetchMore, refetch } =
    useAdminDailyStatisticConnectionQuery({
      variables: { startDate, endDate },
    });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    adminDailyStatisticConnection: {
      nodes: statistics,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  const columns: Array<ColumnProps<IDailyStatistic>> = [
    {
      dataIndex: 'date',
      key: 'date',
      title: 'Date',
    },
    {
      dataIndex: 'newUsersCount',
      key: 'newUsersCount',
      title: 'New Users',
    },
    {
      dataIndex: 'newPayersCount',
      key: 'newPayersCount',
      title: 'Paid Users',
    },
    {
      dataIndex: 'paidUsersCount',
      key: 'paidUsersCount',
      title: 'Paid Users(Accumulated)',
    },
    {
      dataIndex: 'newPaymentsCount',
      key: 'newPaymentsCount',
      title: 'New Payments',
    },
    {
      dataIndex: 'newArticlesCount',
      key: 'newArticlesCount',
      title: 'New Articles',
    },
  ];

  return (
    <>
      <div className='flex justify-between mb-4'>
        <div className='flex space-x-4'>
          <DatePicker.RangePicker
            allowClear={false}
            format='YYYY-MM-DD'
            value={[moment(startDate), moment(endDate)]}
            onChange={(_, dateStrings) => {
              setStartDate(dateStrings[0]);
              setEndDate(dateStrings[1]);
            }}
          />
        </div>
        <Button type='primary' onClick={() => refetch()}>
          Refresh
        </Button>
      </div>
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={statistics}
        rowKey='datetime'
        pagination={false}
        size='small'
      />
      <div style={{ margin: '1rem', textAlign: 'center' }}>
        <Button
          type='link'
          loading={loading}
          disabled={!hasNextPage}
          onClick={() => {
            fetchMore({
              variables: {
                after: endCursor,
                startDate,
                endDate,
              },
            });
          }}
        >
          {hasNextPage ? 'Load More' : 'No More'}
        </Button>
      </div>
    </>
  );
}
