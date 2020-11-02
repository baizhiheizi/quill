import {
  Comment as IComment,
  useCommentConnectionQuery,
  useCreateCommentMutation,
} from '@graphql';
import Editor, { commands } from '@uiw/react-md-editor';
import {
  Button,
  Col,
  Comment,
  Form,
  Input,
  List,
  message,
  Modal,
  Row,
} from 'antd';
import moment from 'moment';
import React from 'react';
import LoadingComponent from '../LoadingComponent/LoadingComponent';

export default function CommentsComponent(props: {
  commentableType: 'Article' | String;
  commentableId: number;
  authorized: boolean;
}) {
  const { commentableType, commentableId, authorized } = props;
  const [commentForm] = Form.useForm();
  const { data, loading, refetch, fetchMore } = useCommentConnectionQuery({
    variables: { commentableType, commentableId },
    notifyOnNetworkStatusChange: true,
  });
  const [createComment] = useCreateCommentMutation({
    update(
      _,
      {
        data: {
          createComment: { error },
        },
      },
    ) {
      if (error) {
        message.error(error);
      } else {
        message.success('提交成功');
        commentForm.setFieldsValue({ content: '' });
        refetch();
      }
    },
  });

  if (!data && loading) {
    return <LoadingComponent />;
  }

  const {
    commentConnection: {
      nodes: comments,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  return (
    <div>
      <Row justify='center'>
        <Col>
          <h4>读者评论</h4>
        </Col>
      </Row>
      <List
        style={{ marginBottom: 30 }}
        dataSource={comments}
        loadMore={
          hasNextPage && (
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
                type='link'
                onClick={() => {
                  fetchMore({
                    updateQuery: (prev, { fetchMoreResult }) => {
                      if (!fetchMoreResult) {
                        return prev;
                      }
                      const connection = fetchMoreResult.commentConnection;
                      connection.nodes = prev.commentConnection.nodes.concat(
                        connection.nodes,
                      );
                      return Object.assign({}, prev, {
                        commentConnection: connection,
                      });
                    },
                    variables: {
                      after: endCursor,
                    },
                  });
                }}
              >
                加载更多
              </Button>
            </div>
          )
        }
        locale={{ emptyText: '暂无评论' }}
        renderItem={(comment: Partial<IComment>) => (
          <li>
            <Comment
              actions={[
                <span
                  onClick={() => {
                    const content = commentForm.getFieldValue('content');
                    commentForm.setFieldsValue({
                      content: `${content}
> @${comment.author.name}:
${comment.content.replace(/^/gm, '> ')}

`,
                    });
                    document.getElementById('comment-form').focus();
                  }}
                >
                  引用
                </span>,
              ]}
              author={comment.author.name}
              avatar={comment.author.avatarUrl}
              content={<Editor.Markdown source={comment.content} />}
              datetime={<span>{moment(comment.createdAt).fromNow()}</span>}
            />
          </li>
        )}
      />
      {authorized && (
        <Form
          form={commentForm}
          initialValues={{
            commentableType,
            commentableId,
          }}
          onFinish={(values) => {
            if (!Boolean(values.content)) {
              message.warn('先写点什么');
            } else {
              Modal.confirm({
                title: '确认提交评论吗?',
                centered: true,
                onOk: () => createComment({ variables: { input: values } }),
                cancelText: '再想想',
                okText: '提交',
              });
            }
          }}
        >
          <Form.Item name='commentableType' style={{ display: 'none' }}>
            <Input />
          </Form.Item>
          <Form.Item name='commentableId' style={{ display: 'none' }}>
            <Input />
          </Form.Item>
          <Form.Item name='content'>
            <Editor
              textareaProps={{
                placeholder: '支持 Markdown 格式',
                id: 'comment-form',
              }}
              autoFocus={false}
              preview='edit'
              height={200}
              commands={[
                commands.bold,
                commands.italic,
                commands.quote,
                commands.hr,
                commands.link,
                commands.code,
                commands.divider,
                commands.codeEdit,
                commands.codePreview,
              ]}
            />
          </Form.Item>
          <Form.Item style={{ textAlign: 'center' }}>
            <Button type='primary' htmlType='submit'>
              确认
            </Button>
          </Form.Item>
        </Form>
      )}
    </div>
  );
}
