import CommentsComponent from '@admin/components/CommentsComponent/CommentsComponent';
import { PageHeader } from 'antd';
import React from 'react';

export default function CommentsPage() {
  return (
    <div>
      <PageHeader title='Comments' />
      <CommentsComponent />
    </div>
  );
}
