import { PageHeader } from 'antd';
import CommentsComponent from 'apps/admin/components/CommentsComponent/CommentsComponent';
import React from 'react';

export default function CommentsPage() {
  return (
    <>
      <PageHeader title='Comments' />
      <CommentsComponent />
    </>
  );
}
