import { Alert, PageHeader, Tabs } from 'antd';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import MyAuthoringSubscriptionsComponent from './components/MyAuthoringSubscriptionsComponent';
import MyCommentingSubscriptionsComponent from './components/MyCommentingSubscriptionsComponent';
import MyReadingSubscriptionsComponent from './components/MyReadingSubscriptionsComponent';
import MyTagSubscriptionsComponent from './components/MyTagSubscriptionsComponent';

export default function SubscriptionsPage() {
  const { t } = useTranslation();
  const [type, setType] = useState<'authoring' | 'reading' | 'commenting'>(
    'authoring',
  );

  return (
    <div>
      <PageHeader title={t('subscriptions_manage')} />
      <Tabs
        activeKey={type}
        onChange={(key: 'authoring' | 'reading' | 'commenting') => setType(key)}
      >
        <Tabs.TabPane key='authoring' tab={t('authoring_subscriptions')}>
          <Alert message={t('authoring_subscriptions_tip')} />
          <br />
          <MyAuthoringSubscriptionsComponent />
        </Tabs.TabPane>
        <Tabs.TabPane key='readering' tab={t('reading_subscriptions')}>
          <Alert message={t('reading_subscriptions_tip')} />
          <br />
          <MyReadingSubscriptionsComponent />
        </Tabs.TabPane>
        <Tabs.TabPane key='commenting' tab={t('commenting_subscriptions')}>
          <Alert message={t('commenting_subscriptions_tip')} />
          <br />
          <MyCommentingSubscriptionsComponent />
        </Tabs.TabPane>
        <Tabs.TabPane key='tag' tab={t('tag_subscriptions')}>
          <Alert message={t('tag_subscriptions_tip')} />
          <br />
          <MyTagSubscriptionsComponent />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
