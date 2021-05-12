import { Col, Row } from 'antd';
import {
  PRSDIGG_MIXIN_GROUP_APP_ID,
  PRSDIGG_MIXIN_GROUP_CODE_ID,
} from 'apps/application/shared';
import { useUserAgent } from 'apps/shared';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function CommunityPage() {
  const { t } = useTranslation();
  const { mixinEnv } = useUserAgent();
  return (
    <div style={{ marginTop: 20 }}>
      <Row gutter={16}>
        <Col>Mixin:</Col>
        <Col>
          <a
            href={
              mixinEnv
                ? `mixin://users/${PRSDIGG_MIXIN_GROUP_APP_ID}`
                : `https://mixin-www.zeromesh.net/codes/${PRSDIGG_MIXIN_GROUP_CODE_ID}`
            }
            target='_blank'
          >
            {t('mixin_group')}
          </a>{' '}
          (Mixin ID: 7000103074){' '}
        </Col>
      </Row>
    </div>
  );
}
