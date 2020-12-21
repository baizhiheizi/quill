import { updateActiveMenu } from '@dashboard/shared';
import { useCurrentUser } from '@shared';
import { PageHeader, Tabs } from 'antd';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import MyArticlesComponent from './components/MyArticlesComponent';
import MyBoughtArticlesComponent from './components/MyBoughtArticlesComponent';

export default function ArticlesPage() {
  updateActiveMenu('articles');
  const { t } = useTranslation();
  const [type, setType] = useState<'author' | 'reader'>('author');
  const currentUser = useCurrentUser();

  return (
    <div>
      <PageHeader title={t('dashboard.menu.articles')} />
      <Tabs
        activeKey={type}
        onChange={(key: 'author' | 'reader') => setType(key)}
      >
        <Tabs.TabPane
          tab={t('dashboard.articlesPage.tabs.author')}
          key='author'
        >
          <MyArticlesComponent />
        </Tabs.TabPane>
        <Tabs.TabPane
          tab={t('dashboard.articlesPage.tabs.reader')}
          key='reader'
        >
          <MyBoughtArticlesComponent />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
