import { ArticleQueryHookResult, useArticleQuery } from '@/graphql';
import MDEditor from '@uiw/react-md-editor';
import { Avatar, Button, Space, Spin } from 'antd';
import moment from 'moment';
import React from 'react';
import { useParams } from 'react-router-dom';

export function Article() {
  const { uuid } = useParams<{ uuid: string }>();
  const { loading, data }: ArticleQueryHookResult = useArticleQuery({
    variables: { uuid },
  });

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
      {article.content ? (
        <MDEditor.Markdown source={article.content} />
      ) : (
        <div style={{ textAlign: 'center' }}>
          <p>
            You need to pay {article.price} PRESS Token to become its reader and
            investor.
          </p>
          <div>
            <Button type='primary'>Pay to Read</Button>
          </div>
        </div>
      )}
    </div>
  );
}
