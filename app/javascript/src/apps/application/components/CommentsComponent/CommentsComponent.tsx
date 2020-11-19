import {
  AlertOutlined,
  DislikeFilled,
  DislikeOutlined,
  LikeFilled,
  LikeOutlined,
} from '@ant-design/icons';
import MarkdownRendererComponent from '@application/components/MarkdownRendererComponent/MarkdownRendererComponent';
import { useCurrentUser, useUserAgent } from '@application/shared';
import {
  Comment as IComment,
  useCommentConnectionQuery,
  useCreateCommentMutation,
  useDownvoteCommentMutation,
  useToggleCommentingSubscribeArticleActionMutation,
  useUpvoteCommentMutation,
} from '@graphql';
import Editor, { commands } from '@uiw/react-md-editor';
import {
  Avatar,
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
import React, { createElement, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import LoadingComponent from '../LoadingComponent/LoadingComponent';

export default function CommentsComponent(props: {
  commentableType?: 'Article' | string;
  commentableId?: string;
  authorized?: boolean;
  articleUuid?: string;
  commentingSubscribed?: boolean;
  refetchArticle?: () => any;
}) {
  const {
    commentableType,
    commentableId,
    authorized,
    articleUuid,
    commentingSubscribed,
    refetchArticle,
  } = props;
  const { isMobile } = useUserAgent();
  const [commentForm] = Form.useForm();
  const { t, i18n } = useTranslation();
  const currentUser = useCurrentUser();
  moment.locale(i18n.language);
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
        message.success(t('messages.successSubmitted'));
        commentForm.setFieldsValue({ content: '' });
        refetchArticle();
        refetch();
      }
    },
  });
  const [upvoteComment] = useUpvoteCommentMutation();
  const [downvoteComment] = useDownvoteCommentMutation();
  const [
    toggleCommentingSubscribeArticleAction,
  ] = useToggleCommentingSubscribeArticleActionMutation({
    update(
      _,
      {
        data: {
          toggleCommentingSubscribeArticleAction: { error },
        },
      },
    ) {
      if (error) {
        message.error(error);
      } else {
        message.success(
          commentingSubscribed
            ? t('messages.successUnsubscribed')
            : t('messages.successSubscribed'),
        );
        refetchArticle();
      }
    },
  });

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
      <Row justify='center'>
        <Col>
          <h3>{t('commentsComponent.title')}</h3>
        </Col>
      </Row>
      <Row justify='center'>
        {authorized && (
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
            {commentingSubscribed
              ? t('commentsComponent.unsubscribeBtn')
              : t('commentsComponent.subscribeBtn')}
          </Button>
        )}
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
                      commentableType,
                      commentableId,
                    },
                  });
                }}
              >
                {t('common.loadMore')}
              </Button>
            </div>
          )
        }
        locale={{ emptyText: t('commentsComponent.emptyText') }}
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
                {t('commentsComponent.deletedText')}
              </div>
            ) : (
              <Comment
                actions={[
                  <span
                    onClick={() => {
                      if (
                        !authorized ||
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
                      if (authorized) {
                        const content = commentForm.getFieldValue('content');
                        commentForm.setFieldsValue({
                          content: `${content}
> @${comment.author.name}([#${comment.id}](#comment-${comment.id})):
${comment.content.replace(/^/gm, '> ')}

`,
                        });
                        document.getElementById('comment-form').focus();
                      }
                    }}
                  >
                    {t('commentsComponent.quoteBtn')}
                  </span>,
                ]}
                author={comment.author.name}
                avatar={
                  <Avatar src={comment.author.avatarUrl}>
                    {comment.author.name[0]}
                  </Avatar>
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
          }}
          onFinish={(values) => {
            if (!Boolean(values.content)) {
              message.warn(t('commentsComponent.form.warning'));
            } else {
              Modal.confirm({
                title: t('commentsComponent.form.confirm'),
                centered: true,
                onOk: () => createComment({ variables: { input: values } }),
                cancelText: t('commentsComponent.form.cancelText'),
                okText: t('commentsComponent.form.okText'),
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
                placeholder: t('commentsComponent.form.placeholder'),
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
              {t('commentsComponent.form.okText')}
            </Button>
          </Form.Item>
        </Form>
      )}
    </div>
  );
}
