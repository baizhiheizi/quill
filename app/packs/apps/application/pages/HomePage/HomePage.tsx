import { Tabs } from 'antd';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useHistory, useLocation } from 'react-router-dom';
import ArticlesComponent from './components/ArticlesComponents';
import CommentsComponent from './components/CommentsComponent';
import TagsComponent from './components/TagsComponent';

export default function HomePage() {
  const { t } = useTranslation();
  const history = useHistory();
  const location = useLocation<any>();
  const [activeTabKey, setActiveTabKey] = useState<
    'default' | 'tags' | 'comments'
  >(location.state?.activeTabKey || 'default');
  return (
    <Tabs
      defaultActiveKey={activeTabKey}
      onChange={(activeKey: any) => {
        setActiveTabKey(activeKey);
        history.replace({
          ...history.location,
          state: { activeTabKey: activeKey },
        });
      }}
    >
      <Tabs.TabPane tab={t('home_page.popularity')} key='popularity'>
        <ArticlesComponent order='default' />
      </Tabs.TabPane>
      <Tabs.TabPane tab={t('home_page.lately')} key='lately'>
        <ArticlesComponent order='lately' />
      </Tabs.TabPane>
      <Tabs.TabPane tab={t('home_page.revenue')} key='revenue'>
        <ArticlesComponent order='revenue' />
      </Tabs.TabPane>
      <Tabs.TabPane tab={t('home_page.tags')} key='tags'>
        <TagsComponent />
      </Tabs.TabPane>
      <Tabs.TabPane tab={t('home_page.comments_zone')} key='comments'>
        <CommentsComponent />
      </Tabs.TabPane>
    </Tabs>
  );
}
