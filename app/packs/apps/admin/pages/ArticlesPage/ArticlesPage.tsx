import { PageHeader } from 'antd';
import { ArticlesComponent } from 'apps/admin/components/ArticlesComponent/ArticlesComponent';
import React from 'react';

export default function ArticlesPage() {
  return (
    <>
      <PageHeader title='Articles' />
      <ArticlesComponent />
    </>
  );
}
