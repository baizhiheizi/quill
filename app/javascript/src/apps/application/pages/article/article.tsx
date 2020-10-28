import { ArticleQueryHookResult, useArticleQuery, User } from '@graphql';
import MDEditor from '@uiw/react-md-editor';
import { Avatar, Button, Col, Row, Space, Spin } from 'antd';
import moment from 'moment';
import React from 'react';
import { Link, useParams } from 'react-router-dom';
import { uuid } from 'uuidv4';
import { encode as encode64 } from 'js-base64';
import { useCurrentUser, usePrsdigg } from '../../shared';
import { Loading } from '../../components';

const traceId = uuid();
export function Article() {
  const { uuid } = useParams<{ uuid: string }>();
  const { appId } = usePrsdigg();
  const currentUser = useCurrentUser();
  const { loading, data }: ArticleQueryHookResult = useArticleQuery({
    fetchPolicy: 'network-only',
    variables: { uuid },
  });

  const memo = encode64(
    JSON.stringify({
      t: 'BUY',
      a: uuid,
    }),
  );

  if (loading) {
    return <Loading />;
  }

  const { article } = data;
  return (
    <div>
      <h1>{article.title}</h1>
      <div style={{ color: '#aaa', marginBottom: '1rem' }}>
        <Space>
          <Avatar size='small' src={article.author.avatarUrl} />
          <span>{article.author.name}</span>
          <span>{moment(article.createdAt).format('YYYY/MM/DD HH:mm')}</span>
        </Space>
      </div>
      <div
        style={{
          padding: '0.5rem 0.5rem',
          background: '#f4f4f4',
          marginBottom: '1rem',
        }}
      >
        {article.intro}
      </div>
      {article.readers.nodes.length > 0 && (
        <div>
          <Row justify='center'>
            <Col>
              <h4>已付费读者</h4>
            </Col>
          </Row>
          <Row justify='center'>
            <Col>
              <Avatar.Group>
                {article.readers.nodes.map((reader: Partial<User>) => (
                  <Avatar src={reader.avatarUrl}>{reader.name[0]}</Avatar>
                ))}
              </Avatar.Group>
            </Col>
          </Row>
        </div>
      )}
      {article.authorized ? (
        <MDEditor.Markdown source={article.content} />
      ) : (
        <div style={{ textAlign: 'center' }}>
          <p>
            付费继续阅读，并享受早期读者奖励（查看<Link to='/rules'>规则</Link>
            ）
          </p>
          <div>
            {currentUser ? (
              <Button
                type='primary'
                href={`https://mixin.one/pay?recipient=${appId}&trace=${traceId}&memo=${memo}&asset=${
                  article.assetId
                }&amount=${article.price.toFixed(8)}`}
              >
                付费阅读
              </Button>
            ) : (
              <Button
                type='primary'
                href={`/login?redirect_uri=${encodeURIComponent(
                  location.href,
                )}`}
              >
                登录
              </Button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
