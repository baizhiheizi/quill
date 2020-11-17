import { Tabs } from 'antd';
import React from 'react';
import { useTranslation } from 'react-i18next';
import ArticlesComponent from './components/ArticlesComponents';
import CommentsComponent from './components/CommentsComponent';

export default function HomePage() {
  const { t } = useTranslation();
  return (
    <Tabs defaultActiveKey='default'>
      <Tabs.TabPane tab={t('homePage.orderByPopularity')} key='default'>
        <ArticlesComponent order='default' />
      </Tabs.TabPane>
      <Tabs.TabPane tab={t('homePage.orderByCreatedAt')} key='lately'>
        <ArticlesComponent order='lately' />
      </Tabs.TabPane>
      <Tabs.TabPane tab={t('homePage.orderByRevenue')} key='revenue'>
        <ArticlesComponent order='revenue' />
      </Tabs.TabPane>
      <Tabs.TabPane tab={t('homePage.commentsZone')} key='comments'>
        <CommentsComponent />
      </Tabs.TabPane>
    </Tabs>
  );
}
