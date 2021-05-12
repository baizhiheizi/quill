import { Alert, PageHeader, Tabs } from 'antd';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import MyAuthoringSubscriptionsComponent from './components/MyAuthoringSubscriptionsComponent';
import MyCommentingSubscriptionsComponent from './components/MyCommentingSubscriptionsComponent';
import MyReadingSubscriptionsComponent from './components/MyReadingSubscriptionsComponent';
import MyTagSubscriptionsComponent from './components/MyTagSubscriptionsComponent';

export default function SubscriptionsPage() {
  const { t } = useTranslation();
  const [type, setType] =
    useState<'authoring' | 'reading' | 'commenting'>('authoring');

  return (
    <div>
      <PageHeader title={t('dashboard.menu.subscriptions')} />
      <Tabs
        activeKey={type}
        onChange={(key: 'authoring' | 'reading' | 'commenting') => setType(key)}
      >
        <Tabs.TabPane
          key='authoring'
          tab={t('dashboard.subscriptions_page.authoring_subscriptions')}
        >
          <Alert
            message={t(
              'dashboard.subscriptions_page.authoring_subscriptions_tip',
            )}
          />
          <br />
          <MyAuthoringSubscriptionsComponent />
        </Tabs.TabPane>
        <Tabs.TabPane
          key='readering'
          tab={t('dashboard.subscriptions_page.reading_subscriptions')}
        >
          <Alert
            message={t(
              'dashboard.subscriptions_page.reading_subscriptions_tip',
            )}
          />
          <br />
          <MyReadingSubscriptionsComponent />
        </Tabs.TabPane>
        <Tabs.TabPane
          key='commenting'
          tab={t('dashboard.subscriptions_page.commenting_subscriptions')}
        >
          <Alert
            message={t(
              'dashboard.subscriptionsPage.commentingSubscriptionsTip',
            )}
          />
          <br />
          <MyCommentingSubscriptionsComponent />
        </Tabs.TabPane>
        <Tabs.TabPane
          key='tag'
          tab={t('dashboard.subscriptions_page.tag_subscriptions')}
        >
          <Alert
            message={t('dashboard.subscriptions_page.tag_subscriptions_tip')}
          />
          <br />
          <MyTagSubscriptionsComponent />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
