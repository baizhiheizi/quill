import {
  AdminArticleConnectionQueryHookResult,
  Article as IArticle,
  useAdminArticleConnectionQuery,
} from '@graphql';
import {
  Avatar,
  Button,
  Divider,
  PageHeader,
  Popconfirm,
  Space,
  Table,
} from 'antd';
import { ColumnProps } from 'antd/lib/table';
import React from 'react';
import LoadingComponent from '../../components/LoadingComponent/LoadingComponent';

export default function ArticlesPage() {
  const {
    data,
    loading,
    fetchMore,
  }: AdminArticleConnectionQueryHookResult = useAdminArticleConnectionQuery();

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
            <Popconfirm title='Are you sure to unblock this article?'>
              <a href='#'>UnBlock</a>
            </Popconfirm>
          ) : (
            <Popconfirm title='Are you sure to block this article?'>
              <a href='#'>Block</a>
            </Popconfirm>
          )}
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
              updateQuery: (prev, { fetchMoreResult }) => {
                if (!fetchMoreResult) {
                  return prev;
                }
                const connection = fetchMoreResult.adminArticleConnection;
                connection.nodes = prev.adminArticleConnection.nodes.concat(
                  connection.nodes,
                );
                return Object.assign({}, prev, {
                  adminArticleConnection: connection,
                });
              },
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
