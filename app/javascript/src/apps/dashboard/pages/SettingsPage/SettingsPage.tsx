import {
  useMyNotificationSettingQuery,
  useUpdateNotificationSettingMutation,
} from '@graphql';
import LoadingComponent from '@dashboard/components/LoadingComponent/LoadingComponent';
import {
  Col,
  Divider,
  message,
  PageHeader,
  Row,
  Space,
  Switch,
  Tabs,
  Typography,
} from 'antd';
import React from 'react';
import { useTranslation } from 'react-i18next';
const { Paragraph } = Typography;

export default function SettingsPage() {
  const { t } = useTranslation();
  const { loading, data } = useMyNotificationSettingQuery();
  const [
    updateNotificationSetting,
    { loading: updating },
  ] = useUpdateNotificationSettingMutation({
    update() {
      message.success(t('messages.successUpdated'));
    },
  });

  if (loading) {
    return <LoadingComponent />;
  }
  const { myNotificationSetting } = data;

  return (
    <div>
      <PageHeader title={t('dashboard.menu.settings')} />
      <Tabs activeKey='notification'>
        <Tabs.TabPane
          key='notification'
          tab={t('dashboard.settingsPage.tabs.notification')}
        >
          <div>
            <Typography>
              <Paragraph>
                {t('dashboard.settingsPage.notification.tipsOfGeneral')}
              </Paragraph>
            </Typography>
            <Divider />
            <Typography>
              <Paragraph>
                {t(
                  'dashboard.settingsPage.notification.tipsOfArticlePublished',
                )}
              </Paragraph>
            </Typography>
            <Row gutter={16}>
              <Col>
                <Space>
                  <Switch
                    loading={updating}
                    checked={myNotificationSetting.articlePublishedWeb}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: { input: { articlePublishedWeb: value } },
                      })
                    }
                  />
                  Web
                </Space>
              </Col>
              <Col>
                <Space>
                  <Switch
                    loading={updating}
                    checked={myNotificationSetting.articlePublishedMixinBot}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: {
                          input: { articlePublishedMixinBot: value },
                        },
                      })
                    }
                  />
                  Mixin Bot
                </Space>
              </Col>
              <Col>
                <Space>
                  <Switch
                    disabled
                    loading={updating}
                    checked={myNotificationSetting.articlePublishedWebhook}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: {
                          input: { articlePublishedWebhook: value },
                        },
                      })
                    }
                  />
                  Webhook
                </Space>
              </Col>
            </Row>
            <Divider />
            <Typography>
              <Paragraph>
                {t('dashboard.settingsPage.notification.tipsOfArticleBought')}
              </Paragraph>
            </Typography>
            <Row gutter={16}>
              <Col>
                <Space>
                  <Switch
                    loading={updating}
                    checked={myNotificationSetting.articleBoughtWeb}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: { input: { articleBoughtWeb: value } },
                      })
                    }
                  />
                  Web
                </Space>
              </Col>
              <Col>
                <Space>
                  <Switch
                    loading={updating}
                    checked={myNotificationSetting.articleBoughtMixinBot}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: {
                          input: { articleBoughtMixinBot: value },
                        },
                      })
                    }
                  />
                  Mixin Bot
                </Space>
              </Col>
              <Col>
                <Space>
                  <Switch
                    disabled
                    loading={updating}
                    checked={myNotificationSetting.articleBoughtWebhook}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: {
                          input: { articleBoughtWebhook: value },
                        },
                      })
                    }
                  />
                  Webhook
                </Space>
              </Col>
            </Row>
            <Divider />
            <Typography>
              <Paragraph>
                {t('dashboard.settingsPage.notification.tipsOfArticleRewarded')}
              </Paragraph>
            </Typography>
            <Row gutter={16}>
              <Col>
                <Space>
                  <Switch
                    loading={updating}
                    checked={myNotificationSetting.articleRewardedWeb}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: { input: { articleRewardedWeb: value } },
                      })
                    }
                  />
                  Web
                </Space>
              </Col>
              <Col>
                <Space>
                  <Switch
                    loading={updating}
                    checked={myNotificationSetting.articleRewardedMixinBot}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: {
                          input: { articleRewardedMixinBot: value },
                        },
                      })
                    }
                  />
                  Mixin Bot
                </Space>
              </Col>
              <Col>
                <Space>
                  <Switch
                    disabled
                    loading={updating}
                    checked={myNotificationSetting.articleRewardedWebhook}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: {
                          input: { articleRewardedWebhook: value },
                        },
                      })
                    }
                  />
                  Webhook
                </Space>
              </Col>
            </Row>
            <Divider />
            <Typography>
              <Paragraph>
                {t('dashboard.settingsPage.notification.tipsOfTaggingCreated')}
              </Paragraph>
            </Typography>
            <Row gutter={16}>
              <Col>
                <Space>
                  <Switch
                    loading={updating}
                    checked={myNotificationSetting.taggingCreatedWeb}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: { input: { taggingCreatedWeb: value } },
                      })
                    }
                  />
                  Web
                </Space>
              </Col>
              <Col>
                <Space>
                  <Switch
                    loading={updating}
                    checked={myNotificationSetting.taggingCreatedMixinBot}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: {
                          input: { taggingCreatedMixinBot: value },
                        },
                      })
                    }
                  />
                  Mixin Bot
                </Space>
              </Col>
              <Col>
                <Space>
                  <Switch
                    disabled
                    loading={updating}
                    checked={myNotificationSetting.taggingCreatedWebhook}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: {
                          input: { taggingCreatedWebhook: value },
                        },
                      })
                    }
                  />
                  Webhook
                </Space>
              </Col>
            </Row>
            <Divider />
            <Typography>
              <Paragraph>
                {t('dashboard.settingsPage.notification.tipsOfCommentCreated')}
              </Paragraph>
            </Typography>
            <Row gutter={16}>
              <Col>
                <Space>
                  <Switch
                    loading={updating}
                    checked={myNotificationSetting.commentCreatedWeb}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: { input: { commentCreatedWeb: value } },
                      })
                    }
                  />
                  Web
                </Space>
              </Col>
              <Col>
                <Space>
                  <Switch
                    loading={updating}
                    checked={myNotificationSetting.commentCreatedMixinBot}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: {
                          input: { commentCreatedMixinBot: value },
                        },
                      })
                    }
                  />
                  Mixin Bot
                </Space>
              </Col>
              <Col>
                <Space>
                  <Switch
                    disabled
                    loading={updating}
                    checked={myNotificationSetting.commentCreatedWebhook}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: {
                          input: { commentCreatedWebhook: value },
                        },
                      })
                    }
                  />
                  Webhook
                </Space>
              </Col>
            </Row>
            <Divider />
            <Typography>
              <Paragraph>
                {t(
                  'dashboard.settingsPage.notification.tipsOfTransferProcessed',
                )}
              </Paragraph>
            </Typography>
            <Row gutter={16}>
              <Col>
                <Space>
                  <Switch
                    loading={updating}
                    checked={myNotificationSetting.transferProcessedWeb}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: { input: { transferProcessedWeb: value } },
                      })
                    }
                  />
                  Web
                </Space>
              </Col>
              <Col>
                <Space>
                  <Switch
                    loading={updating}
                    checked={myNotificationSetting.transferProcessedMixinBot}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: {
                          input: { transferProcessedMixinBot: value },
                        },
                      })
                    }
                  />
                  Mixin Bot
                </Space>
              </Col>
              <Col>
                <Space>
                  <Switch
                    disabled
                    loading={updating}
                    checked={myNotificationSetting.transferProcessedWebhook}
                    onChange={(value) =>
                      updateNotificationSetting({
                        variables: {
                          input: { transferProcessedWebhook: value },
                        },
                      })
                    }
                  />
                  Webhook
                </Space>
              </Col>
            </Row>
            <Divider />
          </div>
        </Tabs.TabPane>
      </Tabs>
    </div>
  );
}
