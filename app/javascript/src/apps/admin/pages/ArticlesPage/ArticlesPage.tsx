import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import {
  AdminArticleConnectionQueryHookResult,
  Article as IArticle,
  useAdminArticleConnectionQuery,
  useAdminBlockArticleMutation,
  useAdminUnblockArticleMutation,
} from '@graphql';
import { useDebounce } from 'ahooks';
import {
  Avatar,
  Button,
  Col,
  Divider,
  Input,
  PageHeader,
  Popconfirm,
  Row,
  Select,
  Space,
  Table,
} from 'antd';
import { ColumnProps } from 'antd/es/table';
import React, { useState } from 'react';
import { Link } from 'react-router-dom';

export default function ArticlesPage() {
  const [query, setQuery] = useState('');
  const [state, setState] = useState('published');
  const debouncedQuery = useDebounce(query, { wait: 500 });
  return (
    <div>
      <PageHeader title='Articles' />
      <Row gutter={16} style={{ marginBottom: '1rem' }}>
        <Col>
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
        </Col>
        <Col>
          <Input
            value={query}
            placeholder='Query article'
            onChange={(e) => setQuery(e.currentTarget.value)}
          />
        </Col>
      </Row>
      <ArticlesComponent query={debouncedQuery} state={state} />
    </div>
  );
}

function ArticlesComponent(props: { query?: string; state?: string }) {
  const { query, state } = props;
  const {
    data,
    loading,
    fetchMore,
  }: AdminArticleConnectionQueryHookResult = useAdminArticleConnectionQuery({
    variables: { query, state },
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
          <Avatar src={article.author.avatarUrl} />
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
      dataIndex: 'revenue',
      key: 'revenue',
      title: 'Revenue',
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
              <Button type='link' disabled={unblocking}>
                UnBlock
              </Button>
            </Popconfirm>
          ) : (
            <Popconfirm
              title='Are you sure to block this article?'
              onConfirm={() =>
                block({ variables: { input: { uuid: article.uuid } } })
              }
            >
              <Button type='link' disabled={blocking}>
                Block
              </Button>
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
    <div>
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={articles}
        rowKey='uuid'
        pagination={false}
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
    </div>
  );
}
