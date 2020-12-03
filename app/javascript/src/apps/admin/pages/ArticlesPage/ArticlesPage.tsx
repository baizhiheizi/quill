import {
  AdminArticleConnectionQueryHookResult,
  Article as IArticle,
  useAdminArticleConnectionQuery,
  useAdminBlockArticleMutation,
  useAdminUnblockArticleMutation,
} from '@graphql';
import {
  Avatar,
  Button,
  Divider,
  message,
  PageHeader,
  Popconfirm,
  Space,
  Table,
} from 'antd';
import { ColumnProps } from 'antd/lib/table';
import React from 'react';
import { Link } from 'react-router-dom';
import LoadingComponent from '../../components/LoadingComponent/LoadingComponent';

export default function ArticlesPage() {
  const {
    data,
    loading,
    fetchMore,
    refetch,
  }: AdminArticleConnectionQueryHookResult = useAdminArticleConnectionQuery();
  const [block, { loading: blocking }] = useAdminBlockArticleMutation({
    update(_, { data: { error: err } }) {
      if (err) {
        message.error(err);
      } else {
        message.success('Successfully Blocked!');
        refetch();
      }
    },
  });
  const [unblock, { loading: unblocking }] = useAdminUnblockArticleMutation({
    update(_, { data: { error: err } }) {
      if (err) {
        message.error(err);
      } else {
        message.success('Successfully Unblocked!');
        refetch();
      }
    },
  });

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
      <PageHeader title='Articles' />
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
