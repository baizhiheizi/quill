import { Button, Card, Col, Row, Tag, Typography } from 'antd';
import LoadingComponent from 'apps/application/components/LoadingComponent/LoadingComponent';
import { Tag as ITag, useTagConnectionQuery } from 'graphqlTypes';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { useHistory } from 'react-router-dom';

export default function TagsComponent() {
  const { loading, data, fetchMore } = useTagConnectionQuery();
  const { t } = useTranslation();
  const history = useHistory();

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    tagConnection: {
      nodes: tags,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  return (
    <div>
      <Row wrap gutter={[8, 8]}>
        {tags.map((tag: ITag) => (
          <Col key={tag.id} xs={24} sm={12} md={12} lg={8}>
            <Card
              size='small'
              hoverable
              onClick={() => history.push(`/articles?tag=${tag.name}`)}
              style={{
                borderTop: `3px solid ${tag.color}`,
                borderTopLeftRadius: 10,
                borderTopRightRadius: 10,
                margin: '0 0.5rem 1rem',
              }}
            >
              <div>
                <Tag
                  style={{
                    maxWidth: '100%',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                  }}
                  color={tag.color}
                >
                  #{tag.name}
                </Tag>
              </div>
              <div>
                <Typography.Text type='secondary'>
                  {t('tag.articles_count')} {tag.articlesCount}
                </Typography.Text>
              </div>
            </Card>
          </Col>
        ))}
      </Row>
      {hasNextPage && (
        <div
          style={{
            textAlign: 'center',
            marginTop: 12,
            height: 32,
            lineHeight: '32px',
          }}
        >
          <Button
            loading={loading}
            onClick={() => {
              fetchMore({
                variables: {
                  after: endCursor,
                },
              });
            }}
          >
            {t('load_more')}
          </Button>
        </div>
      )}
    </div>
  );
}
