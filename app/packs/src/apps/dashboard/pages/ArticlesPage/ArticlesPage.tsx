import { Button, PageHeader, Tabs } from 'antd';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import MyArticlesComponent from './components/MyArticlesComponent';
import MyBoughtArticlesComponent from './components/MyBoughtArticlesComponent';

export default function ArticlesPage() {
  const { t } = useTranslation();
  const [type, setType] = useState<
    'published' | 'bought' | 'hidden' | 'blocked'
  >('bought');

  return (
    <div>
      <PageHeader
        title={t('dashboard.menu.articles')}
        extra={[
          <Button key='new' type='primary'>
            <Link to='/articles/new'>{t('article.form.newBtn')}</Link>
          </Button>,
        ]}
      />
      <Tabs
        activeKey={type}
        onChange={(key: 'published' | 'bought' | 'hidden' | 'blocked') =>
          setType(key)
        }
      >
        <Tabs.TabPane
          tab={t('dashboard.articlesPage.tabs.bought')}
          key='bought'
        >
          <MyBoughtArticlesComponent />
        </Tabs.TabPane>
        <Tabs.TabPane
          tab={t('dashboard.articlesPage.tabs.published')}
          key='published'
        >
          <MyArticlesComponent state='published' />
        </Tabs.TabPane>
        <Tabs.TabPane
          tab={t('dashboard.articlesPage.tabs.hidden')}
          key='hidden'
        >
          <MyArticlesComponent state='hidden' />
        </Tabs.TabPane>
        <Tabs.TabPane
          tab={t('dashboard.articlesPage.tabs.blocked')}
          key='blocked'
        >
          <MyArticlesComponent state='blocked' />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
