import { PageHeader } from 'antd';
import ArticleSnapshotsComponent from 'apps/admin/components/ArticleSnapshotsComponent/ArticleSnapshotsComponent';
import React from 'react';

export default function ArticleSnapshotsPage() {
  return (
    <>
      <PageHeader title='Article Snapshots' />
      <ArticleSnapshotsComponent />
    </>
  );
}
