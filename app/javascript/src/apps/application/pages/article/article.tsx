import { ArticleQueryHookResult, useArticleQuery } from '@graphql';
import MDEditor from '@uiw/react-md-editor';
import { Avatar, Button, Space, Spin } from 'antd';
import moment from 'moment';
import React from 'react';
import { useParams } from 'react-router-dom';
import { uuid } from 'uuidv4';
import { encode as encode64 } from 'js-base64';
import { useCurrentUser, usePrsdigg } from '../../shared';

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
    return <Spin />;
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
      {article.authorized ? (
        <MDEditor.Markdown source={article.content} />
      ) : (
        <div style={{ textAlign: 'center' }}>
          <p>
            You need to pay {article.price} PRESS Token to become its reader and
            investor.
          </p>
          <div>
            {currentUser ? (
              <Button
                type='primary'
                href={`https://mixin.one/pay?recipient=${appId}&trace=${traceId}&memo=${memo}&asset=${
                  article.assetId
                }&amount=${article.price.toFixed(8)}`}
              >
                Pay to Read
              </Button>
            ) : (
              <Button
                type='primary'
                href={`/login?redirect_uri=${encodeURIComponent(
                  location.href,
                )}`}
              >
                Login to pay
              </Button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
