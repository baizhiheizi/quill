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
        title={t('articles_manage')}
        extra={[
          <Button key='new' type='primary'>
            <Link to='/articles/new'>{t('new_article')}</Link>
          </Button>,
        ]}
      />
      <Tabs
        activeKey={type}
        onChange={(key: 'published' | 'bought' | 'hidden' | 'blocked') =>
          setType(key)
        }
      >
        <Tabs.TabPane tab={t('bought')} key='bought'>
          <MyBoughtArticlesComponent />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('published')} key='published'>
          <MyArticlesComponent state='published' />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('hidden')} key='hidden'>
          <MyArticlesComponent state='hidden' />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('blocked')} key='blocked'>
          <MyArticlesComponent state='blocked' />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
