import { Button, PageHeader, Tabs } from 'antd';
import { useCreateArticleMutation } from 'graphqlTypes';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useHistory } from 'react-router-dom';
import MyArticlesComponent from './components/MyArticlesComponent';
import MyBoughtArticlesComponent from './components/MyBoughtArticlesComponent';

export default function ArticlesPage() {
  const { t } = useTranslation();
  const history = useHistory();
  const [type, setType] = useState<
    'drafted' | 'published' | 'bought' | 'hidden' | 'blocked'
  >('drafted');
  const [createArticle] = useCreateArticleMutation({
    update: (
      _,
      {
        data: {
          createArticle: { uuid },
        },
      },
    ) => {
      history.push(`/articles/${uuid}/edit`);
    },
  });

  return (
    <div>
      <PageHeader
        title={t('articles_manage')}
        extra={[
          <Button key='new' type='primary' onClick={() => createArticle()}>
            {t('write')}
          </Button>,
        ]}
      />
      <Tabs
        activeKey={type}
        onChange={(key: 'published' | 'bought' | 'hidden' | 'blocked') =>
          setType(key)
        }
      >
        <Tabs.TabPane tab={t('drafted')} key='drafted'>
          <MyArticlesComponent state='drafted' />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('published')} key='published'>
          <MyArticlesComponent state='published' />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('hidden')} key='hidden'>
          <MyArticlesComponent state='hidden' />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('bought')} key='bought'>
          <MyBoughtArticlesComponent />
        </Tabs.TabPane>
        <Tabs.TabPane tab={t('blocked')} key='blocked'>
          <MyArticlesComponent state='blocked' />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
