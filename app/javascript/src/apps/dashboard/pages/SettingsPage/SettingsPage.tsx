import { PageHeader, Tabs } from 'antd';
import React from 'react';
import { useTranslation } from 'react-i18next';
import NotificationSettingComponent from './components/NotificationSettingComponent';

export default function SettingsPage() {
  const { t } = useTranslation();

  return (
    <div>
      <PageHeader title={t('dashboard.menu.settings')} />
      <Tabs activeKey='notification'>
        <Tabs.TabPane
          key='notification'
          tab={t('dashboard.settingsPage.tabs.notification')}
        >
          <NotificationSettingComponent />
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
