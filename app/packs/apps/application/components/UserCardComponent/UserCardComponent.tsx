import { Avatar, Button, Card, Col, Row } from 'antd';
import { useCurrentUser } from 'apps/shared';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';

export default function UserCardComponent(props: {
  user: {
    avatar: string;
    bio?: string;
    name: string;
    mixinId: string;
  };
}) {
  const {
    user: { avatar, bio, name, mixinId },
  } = props;
  const { currentUser } = useCurrentUser();
  const { t } = useTranslation();
  return (
    <Card>
      <Card.Meta
        avatar={<Avatar src={avatar} />}
        title={
          <Row style={{ alignItems: 'center' }}>
            <Col style={{ flex: 1, marginRight: 10 }}>{name}</Col>
            {mixinId && (!currentUser || currentUser.mixinId !== mixinId) && (
              <Col>
                <Button type='primary' shape='round' size='small'>
                  <Link to={`/users/${mixinId}`}>{t('detail')}</Link>
                </Button>
              </Col>
            )}
          </Row>
        }
        description={bio || t('user.default_bio')}
      />
    </Card>
  );
}
