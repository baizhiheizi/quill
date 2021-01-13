import { updateActiveMenu } from '@dashboard/shared';
import { Alert, PageHeader, Tabs } from 'antd';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import MyAuthoringSubscriptionsComponent from './components/MyAuthoringSubscriptionsComponent';
import MyReadingSubscriptionsComponent from './components/MyReadingSubscriptionsComponent';

export default function SubscriptionsPage() {
  updateActiveMenu('subscriptions');
  const { t } = useTranslation();
  const [type, setType] = useState<'authoring' | 'reading' | 'commenting'>(
    'authoring',
  );

  return (
    <div>
      <PageHeader title={t('dashboard.menu.subscriptions')} />
      <Tabs
        activeKey={type}
        onChange={(key: 'authoring' | 'reading' | 'commenting') => setType(key)}
      >
        <Tabs.TabPane
          key='authoring'
          tab={t('dashboard.subscriptionsPage.authoringSubscriptions')}
        >
          <Alert
            message={
              <span>
                订阅的作者<b>发表新文章</b>时，您将收到通知
              </span>
            }
          />
          <br />
          <MyAuthoringSubscriptionsComponent />
        </Tabs.TabPane>
        <Tabs.TabPane
          key='readering'
          tab={t('dashboard.subscriptionsPage.readingSubscriptions')}
        >
          <Alert
            message={
              <span>
                订阅的读者<b>购买新文章</b>时，您将收到通知
              </span>
            }
          />
          <br />
          <MyReadingSubscriptionsComponent />
        </Tabs.TabPane>
        <Tabs.TabPane
          key='commenting'
          tab={t('dashboard.subscriptionsPage.commentingSubscriptions')}
        ></Tabs.TabPane>
      </Tabs>
    </div>
  );
}
