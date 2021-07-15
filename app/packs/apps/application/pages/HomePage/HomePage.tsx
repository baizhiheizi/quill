import { Tabs } from 'antd';
import { useCurrentUser } from 'apps/shared';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useHistory, useLocation } from 'react-router-dom';
import ArticlesComponent from './components/ArticlesComponents';
import CommentsComponent from './components/CommentsComponent';
import TagsComponent from './components/TagsComponent';

export default function HomePage() {
  const { t } = useTranslation();
  const { currentUser } = useCurrentUser();
  const history = useHistory();
  const location = useLocation<any>();
  const [activeTabKey, setActiveTabKey] = useState<
    'popularity' | 'lately' | 'revenue' | 'subscribed' | 'tags' | 'comments'
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
      <Tabs.TabPane tab={t('order_by_popularity')} key='popularity'>
        <ArticlesComponent filter='default' />
      </Tabs.TabPane>
      {currentUser && (
        <Tabs.TabPane tab={t('subscribed')} key='subscribed'>
          <ArticlesComponent filter='subscribed' />
        </Tabs.TabPane>
      )}
      <Tabs.TabPane tab={t('order_by_lately')} key='lately'>
        <ArticlesComponent filter='lately' />
      </Tabs.TabPane>
      <Tabs.TabPane tab={t('order_by_revenue')} key='revenue'>
        <ArticlesComponent filter='revenue' />
      </Tabs.TabPane>
      <Tabs.TabPane tab={t('tags')} key='tags'>
        <TagsComponent />
      </Tabs.TabPane>
      <Tabs.TabPane tab={t('comments_zone')} key='comments'>
        <CommentsComponent />
      </Tabs.TabPane>
    </Tabs>
  );
}
