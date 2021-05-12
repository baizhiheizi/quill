import { PageHeader, Tabs } from 'antd';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useHistory, useLocation } from 'react-router-dom';
import AccessTokensComponent from './components/AccessTokensComponent';
import NotificationSettingComponent from './components/NotificationSettingComponent';

export default function SettingsPage() {
  const location = useLocation<{ activeKey: string }>();
  const history = useHistory();
  const { t } = useTranslation();
  const [activeKey, setActiveKey] = useState(
    location.state?.activeKey || 'notification',
  );

  return (
    <>
      <PageHeader title={t('settings')} />
      <Tabs
        activeKey={activeKey}
        onChange={(value) => {
          setActiveKey(value);
          history.replace({
            ...location,
            state: {
              ...location.state,
              activeKey: value,
            },
          });
        }}
      >
        <Tabs.TabPane key='notification' tab={t('notification')}>
          <NotificationSettingComponent />
        </Tabs.TabPane>
        <Tabs.TabPane key='accessToken' tab={t('access_token')}>
          <AccessTokensComponent />
        </Tabs.TabPane>
      </Tabs>
    </>
  );
}
