import { ArticleQueryHookResult, useArticleQuery, User } from '@graphql';
import MDEditor from '@uiw/react-md-editor';
import { Avatar, Button, Col, Divider, Row, Space } from 'antd';
import { encode as encode64 } from 'js-base64';
import moment from 'moment';
import React, { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { v4 as uuid } from 'uuid';
import { Comments, Loading } from '../../components';
import { useCurrentUser, usePrsdigg } from '../../shared';

const traceId = uuid();
export function Article() {
  const { uuid } = useParams<{ uuid: string }>();
  const [paying, setPaying] = useState(false);
  const { appId } = usePrsdigg();
  const currentUser = useCurrentUser();
  const { loading, data, refetch }: ArticleQueryHookResult = useArticleQuery({
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

  const handlePaying = () => {
    setPaying(true);
    const payUrl = `https://mixin.one/pay?recipient=${appId}&trace=${traceId}&memo=${memo}&asset=${
      article.assetId
    }&amount=${article.price.toFixed(8)}`;
    location.replace(payUrl);
  };
  const handlePaid = () => {
    refetch();
    setPaying(false);
  };

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
          marginBottom: '2rem',
        }}
      >
        {article.intro}
      </div>
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
              paying ? (
                <Button onClick={handlePaid}>支付完成</Button>
              ) : (
                <Button type='primary' onClick={handlePaying}>
                  付费阅读
                </Button>
              )
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
      {article.readers.nodes.length > 0 && (
        <div>
          <Divider />
          <Row justify='center'>
            <Col>
              <h4>已付费读者</h4>
            </Col>
          </Row>
          <Row justify='center'>
            <Col>
              <Avatar.Group>
                {article.readers.nodes.map((reader: Partial<User>) => (
                  <Avatar key={reader.mixinId} src={reader.avatarUrl}>
                    {reader.name[0]}
                  </Avatar>
                ))}
              </Avatar.Group>
            </Col>
          </Row>
        </div>
      )}
      <Divider />
      <Comments
        commentableType='Article'
        commentableId={article.id}
        authorized={article.authorized}
      />
    </div>
  );
}
