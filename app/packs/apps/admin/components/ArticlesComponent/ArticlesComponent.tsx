import { useDebounce } from 'ahooks';
import {
  Avatar,
  Button,
  Divider,
  Input,
  Popconfirm,
  Select,
  Space,
  Table,
} from 'antd';
import { ColumnProps } from 'antd/es/table';
import LoadingComponent from 'apps/admin/components/LoadingComponent/LoadingComponent';
import {
  AdminArticleConnectionQueryHookResult,
  Article as IArticle,
  useAdminArticleConnectionQuery,
  useAdminBlockArticleMutation,
  useAdminUnblockArticleMutation,
} from 'graphqlTypes';
import React, { useState } from 'react';
import { Link } from 'react-router-dom';

export function ArticlesComponent(props: { authorMixinUuid?: string }) {
  const { authorMixinUuid } = props;
  const [query, setQuery] = useState('');
  const [state, setState] = useState('published');
  const debouncedQuery = useDebounce(query, { wait: 500 });

  const {
    data,
    loading,
    fetchMore,
    refetch,
  }: AdminArticleConnectionQueryHookResult = useAdminArticleConnectionQuery({
    variables: { query: debouncedQuery, state, authorMixinUuid },
  });
  const [block, { loading: blocking }] = useAdminBlockArticleMutation();
  const [unblock, { loading: unblocking }] = useAdminUnblockArticleMutation();

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    adminArticleConnection: {
      nodes: articles,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  const columns: Array<ColumnProps<IArticle>> = [
    {
      dataIndex: 'uuid',
      key: 'uuid',
      title: 'UUID',
    },
    {
      dataIndex: 'author',
      key: 'author',
      render: (_, article) => (
        <Space>
          <Avatar src={article.author.avatar} />
          {article.author.name}
        </Space>
      ),
      title: 'Author',
    },
    {
      dataIndex: 'title',
      key: 'title',
      title: 'Title',
    },
    {
      dataIndex: 'state',
      key: 'state',
      title: 'State',
    },
    {
      dataIndex: 'revenueUsd',
      key: 'revenueUsd',
      title: 'Revenue(USD)',
    },
    {
      dataIndex: 'commentsCount',
      key: 'commentsCount',
      title: 'Comments',
    },
    {
      dataIndex: 'createdAt',
      key: 'createdAt',
      title: 'CreatedAt',
    },
    {
      dataIndex: 'actions',
      key: 'actions',
      render: (_, article) => (
        <span>
          {article.state === 'blocked' ? (
            <Popconfirm
              title='Are you sure to unblock this article?'
              onConfirm={() =>
                unblock({ variables: { input: { uuid: article.uuid } } })
              }
            >
              <a
                className={unblocking ? 'cursor-not-allowed' : 'cursor-pointer'}
              >
                UnBlock
              </a>
            </Popconfirm>
          ) : (
            <Popconfirm
              title='Are you sure to block this article?'
              onConfirm={() =>
                block({ variables: { input: { uuid: article.uuid } } })
              }
            >
              <a className={blocking ? 'cursor-not-allowed' : 'cursor-pointer'}>
                Block
              </a>
            </Popconfirm>
          )}
          <Divider type='vertical' />
          <Link to={`/articles/${article.uuid}`}>Detail</Link>
          <Divider type='vertical' />
          <a href={`/articles/${article.uuid}`} target='_blank'>
            View
          </a>
        </span>
      ),
      title: 'Actions',
    },
  ];

  return (
    <>
      <div className='flex justify-between mb-4'>
        <div className='flex space-x-4'>
          <Select
            style={{ width: 200 }}
            value={state}
            onChange={(value) => setState(value)}
          >
            <Select.Option value='published'>Published</Select.Option>
            <Select.Option value='hidden'>Hidden</Select.Option>
            <Select.Option value='blocked'>Blocked</Select.Option>
            <Select.Option value='all'>All</Select.Option>
          </Select>
          <Input
            value={query}
            placeholder='Query article'
            onChange={(e) => setQuery(e.currentTarget.value)}
          />
        </div>
        <Button type='primary' onClick={() => refetch()}>
          Refresh
        </Button>
      </div>
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={articles}
        rowKey='uuid'
        pagination={false}
        size='small'
      />
      <div style={{ margin: '1rem', textAlign: 'center' }}>
        <Button
          type='link'
          loading={loading}
          disabled={!hasNextPage}
          onClick={() => {
            fetchMore({
              variables: {
                after: endCursor,
                query,
                state,
              },
            });
          }}
        >
          {hasNextPage ? 'Load More' : 'No More'}
        </Button>
      </div>
    </>
  );
}
