import {
  AlertOutlined,
  DislikeFilled,
  DislikeOutlined,
  LikeFilled,
  LikeOutlined,
} from '@ant-design/icons';
import Editor, { commands } from '@uiw/react-md-editor';
import {
  Avatar,
  Button,
  Comment,
  Form,
  Input,
  List,
  message,
  Modal,
  Select,
} from 'antd';
import {
  MarkdownRendererComponent,
  useCurrentUser,
  useUserAgent,
} from 'apps/shared';
import {
  Comment as IComment,
  useCommentConnectionQuery,
  useCreateCommentMutation,
  useDownvoteCommentMutation,
  useToggleCommentingSubscribeArticleActionMutation,
  useUpvoteCommentMutation,
} from 'graphqlTypes';
import moment from 'moment';
import React, { createElement, useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import LoadingComponent from '../LoadingComponent/LoadingComponent';
import LoadMoreComponent from '../LoadMoreComponent/LoadMoreComponent';
import LoginModalComponent from '../LoginModalComponent/LoginModalComponent';

export default function CommentsComponent(props: {
  commentableType?: 'Article' | string;
  commentableId?: string;
  authorized?: boolean;
  articleUuid?: string;
  commentingSubscribed?: boolean;
}) {
  const {
    commentableType,
    commentableId,
    authorized,
    articleUuid,
    commentingSubscribed,
  } = props;
  const { isMobile } = useUserAgent();
  const [commentForm] = Form.useForm();
  const { currentUser } = useCurrentUser();
  const { t, i18n } = useTranslation();
  moment.locale(i18n.language);
  const [orderBy, setOrderBy] = useState<'desc' | 'asc' | 'upvotes'>('upvotes');
  const ref = useRef(null);
  const { data, loading, refetch, fetchMore } = useCommentConnectionQuery({
    variables: { commentableType, commentableId, orderBy },
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
        message.success(t('success_submitted'));
        commentForm.setFieldsValue({ content: '' });
        refetch({ commentableId, commentableType, orderBy: 'desc' });
        setOrderBy('desc');
      }
    },
  });
  const [upvoteComment] = useUpvoteCommentMutation();
  const [downvoteComment] = useDownvoteCommentMutation();
  const [toggleCommentingSubscribeArticleAction] =
    useToggleCommentingSubscribeArticleActionMutation();

  useEffect(() => {
    if (location.hash && document.querySelector(location.hash)) {
      setTimeout(() => {
        document
          .querySelector(location.hash)
          .scrollIntoView({ behavior: 'smooth' });
      }, 100);
    }
  }, [data]);

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
      <div className='flex items-center justify-center mb-2'>
        <h3>{t('comments')}</h3>
      </div>
      <div className='flex items-center justify-center mb-2'>
        {authorized && currentUser && (
          <Button
            type='dashed'
            shape='round'
            size='small'
            danger={commentingSubscribed}
            onClick={() =>
              toggleCommentingSubscribeArticleAction({
                variables: { input: { uuid: articleUuid } },
              })
            }
            icon={<AlertOutlined />}
          >
            {commentingSubscribed ? t('unsubscribe') : t('subscribe')}
          </Button>
        )}
      </div>
      <div className='flex items-center justify-end'>
        <Select
          value={orderBy}
          bordered={false}
          onSelect={(value) => setOrderBy(value)}
        >
          <Select.Option value='desc'>{t('desc')}</Select.Option>
          <Select.Option value='asc'>{t('asc')}</Select.Option>
          <Select.Option value='upvotes'>{t('upvotes')}</Select.Option>
        </Select>
      </div>
      <List
        style={{ marginBottom: 30 }}
        dataSource={comments}
        loadMore={
          <LoadMoreComponent
            hasNextPage={hasNextPage}
            loading={loading}
            fetchMore={() => {
              fetchMore({
                variables: {
                  after: endCursor,
                  commentableType,
                  commentableId,
                  orderBy,
                },
              });
            }}
          />
        }
        locale={{ emptyText: t('no_comments') }}
        renderItem={(comment: Partial<IComment>) => (
          <li
            id={`comment-${comment.id}`}
            className={isMobile.phone ? 'blockquote-collapsed' : ''}
          >
            {comment.deletedAt ? (
              <div
                style={{
                  padding: '1rem 0',
                  color: '#aaa',
                  textDecoration: 'line-through',
                }}
              >
                {t('comment_deleted')}
              </div>
            ) : (
              <Comment
                actions={[
                  <span
                    onClick={() => {
                      if (
                        !authorized ||
                        !currentUser ||
                        comment.upvoted ||
                        comment.author.mixinId === currentUser.mixinId
                      ) {
                        return;
                      } else {
                        upvoteComment({
                          variables: { input: { id: comment.id } },
                        });
                      }
                    }}
                  >
                    {createElement(comment.upvoted ? LikeFilled : LikeOutlined)}
                    <span style={{ paddingLeft: 8, cursor: 'auto' }}>
                      {comment.upvotesCount}
                    </span>
                  </span>,
                  <span
                    onClick={() => {
                      if (
                        !authorized ||
                        !currentUser ||
                        comment.downvoted ||
                        comment.author.mixinId === currentUser.mixinId
                      ) {
                        return;
                      } else {
                        downvoteComment({
                          variables: { input: { id: comment.id } },
                        });
                      }
                    }}
                  >
                    {createElement(
                      comment.downvoted ? DislikeFilled : DislikeOutlined,
                    )}
                    <span style={{ paddingLeft: 8, cursor: 'auto' }}>
                      {comment.downvotesCount}
                    </span>
                  </span>,
                  <span
                    onClick={() => {
                      if (authorized && currentUser) {
                        const content = commentForm.getFieldValue('content');
                        commentForm.setFieldsValue({
                          content: `${content || ''}
> @${comment.author.name}([#${comment.id}](#comment-${comment.id})):
${comment.content.replace(/^/gm, '> ')}

`,
                        });
                        document.getElementsByTagName('textarea')[0]?.focus();
                      }
                    }}
                  >
                    {t('quote')}
                  </span>,
                ]}
                author={comment.author.name}
                avatar={
                  <Link to={`/users/${comment.author.mixinId}`}>
                    <Avatar src={comment.author.avatar}>
                      {comment.author.name[0]}
                    </Avatar>
                  </Link>
                }
                content={<MarkdownRendererComponent source={comment.content} />}
                datetime={<span>{moment(comment.createdAt).fromNow()}</span>}
              />
            )}
          </li>
        )}
      />
      {authorized && (
        <Form
          form={commentForm}
          initialValues={{
            commentableType,
            commentableId,
            content: '',
          }}
          onFinish={(values) => {
            if (!currentUser) {
              return;
            } else if (!Boolean(values.content)) {
              message.warn(t('write_something_first'));
            } else {
              Modal.confirm({
                title: t('confirm_to_submit'),
                centered: true,
                onOk: () => createComment({ variables: { input: values } }),
                cancelText: t('later'),
                okText: t('submit'),
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
                placeholder: t('markdown_supported'),
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
            {currentUser ? (
              <Button type='primary' htmlType='submit'>
                {t('submit')}
              </Button>
            ) : (
              <LoginModalComponent>
                <Button type='primary'>{t('connect_wallet')}</Button>
              </LoginModalComponent>
            )}
          </Form.Item>
        </Form>
      )}
    </div>
  );
}
