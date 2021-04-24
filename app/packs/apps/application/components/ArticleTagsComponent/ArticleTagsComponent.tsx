import { Col, Row, Tag, Tooltip } from 'antd';
import { Tag as TagType } from 'graphqlTypes';
import React from 'react';
import { Link } from 'react-router-dom';

export default function ArticleTagsComponent(props: { tags: TagType[] }) {
  const { tags } = props;
  return (
    <Row gutter={[0, 8]} wrap>
      {tags.map((tag: TagType) => (
        <Col key={tag.id}>
          <Tooltip title={tag.name}>
            <Link to={`/tags/${tag.id}`}>
              <Tag
                color={tag.color}
                style={{
                  maxWidth: 200,
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                }}
              >
                #{tag.name}
              </Tag>
            </Link>
          </Tooltip>
        </Col>
      ))}
    </Row>
  );
}
