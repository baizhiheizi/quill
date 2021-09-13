import { Alert, PageHeader, Tabs } from 'antd';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import MyCommentingSubscriptionsComponent from './components/MyCommentingSubscriptionsComponent';
import MySubscribersComponent from './components/MySubscribersComponent';
import MySubscribingsComponent from './components/MySubscribingsComponent';
import MyTagSubscriptionsComponent from './components/MyTagSubscriptionsComponent';

export default function SubscriptionsPage() {
  const { t } = useTranslation();
  const [type, setType] = useState<
    'subscribers' | 'subscribing' | 'commenting'
  >('subscribing');

  return (
    <div>
      <PageHeader title={t('subscriptions_manage')} />
      <Tabs
        activeKey={type}
        onChange={(key: 'subscribers' | 'subscribing' | 'commenting') =>
          setType(key)
        }
      >
        <Tabs.TabPane key='subscribing' tab={t('subscribing')}>
          <MySubscribingsComponent />
        </Tabs.TabPane>
        <Tabs.TabPane key='subscribers' tab={t('subscribers')}>
          <MySubscribersComponent />
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
