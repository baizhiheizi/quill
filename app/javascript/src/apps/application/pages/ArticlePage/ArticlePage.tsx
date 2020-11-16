import {
  DislikeOutlined,
  HeartOutlined,
  LikeOutlined,
  ShareAltOutlined,
} from '@ant-design/icons';
import CommentsComponent from '@application/components/CommentsComponent/CommentsComponent';
import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import {
  handleShare,
  PAGE_TITLE,
  useCurrentUser,
  useMixin,
  usePrsdigg,
} from '@application/shared';
import {
  ArticleQueryHookResult,
  useArticleQuery,
  useDownvoteArticleMutation,
  User,
  useUpvoteArticleMutation,
} from '@graphql';
import MDEditor from '@uiw/react-md-editor';
import {
  Alert,
  Avatar,
  Button,
  Card,
  Col,
  Divider,
  message,
  Modal,
  Progress,
  Radio,
  Row,
  Space,
  Statistic,
} from 'antd';
import { encode as encode64 } from 'js-base64';
import moment from 'moment';
import React, { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { v4 as uuidv4 } from 'uuid';
import NotFoundPage from '../NotFoundPage/NotFoundPage';
import './ArticlePage.less';

export default function ArticlePage() {
  const { uuid } = useParams<{ uuid: string }>();
  const [paying, setPaying] = useState(false);
  const [rewardModalVisible, setRewardModalVisible] = useState(false);
  const [rewardAmount, setRewardAmount] = useState(1);
  const { appId } = usePrsdigg();
  const { mixinEnv } = useMixin();
  const currentUser = useCurrentUser();
  const {
    loading,
    data,
    refetch,
    startPolling,
    stopPolling,
  }: ArticleQueryHookResult = useArticleQuery({
    fetchPolicy: 'network-only',
    variables: { uuid },
  });
  const [upvoteArticle] = useUpvoteArticleMutation({
    update(
      _,
      {
        data: {
          upvoteArticle: { error },
        },
      },
    ) {
      if (error) {
        message.error(error);
      } else {
        message.success('感谢反馈');
        refetch();
      }
    },
  });
  const [downvoteArticle] = useDownvoteArticleMutation({
    update(
      _,
      {
        data: {
          downvoteArticle: { error },
        },
      },
    ) {
      if (error) {
        message.error(error);
      } else {
        message.success('感谢反馈');
        refetch();
      }
    },
  });

  useEffect(() => {
    return () => (document.title = PAGE_TITLE);
  }, [uuid]);

  useEffect(() => {
    return () => stopPolling();
  }, [startPolling, stopPolling]);

  const memo = encode64(
    JSON.stringify({
      t: 'BUY',
      a: uuid,
    }),
  );

  if (loading) {
    return <LoadingComponent />;
  }

  const { article } = data;

  if (article.authorized) {
    stopPolling();
  }

  if (!article) {
    return <NotFoundPage />;
  }

  document.title = `${article.title} - ${article.author.name}`;

  const handlePaying = () => {
    if (mixinEnv) {
      setPaying(true);
      const payUrl = `mixin://pay?recipient=${appId}&trace=${
        article.paymentTraceId
      }&memo=${memo}&asset=${article.assetId}&amount=${article.price.toFixed(
        8,
      )}`;
      location.replace(payUrl);
      handlePaid();
    } else {
      message.warn('请在 Mixin Messenger 中付款');
    }
  };
  const handlePaid = () => {
    startPolling(1500);
  };
  const handleRewarding = () => {
    if (mixinEnv) {
      const payUrl = `mixin://pay?recipient=${appId}&trace=${uuidv4()}&memo=${encode64(
        JSON.stringify({ t: 'REWARD', a: uuid }),
      )}&asset=${article.assetId}&amount=${rewardAmount.toFixed(8)}`;
      location.replace(payUrl);
      setRewardModalVisible(false);
    } else {
      message.warn('请在 Mixin Messenger 中赞赏');
    }
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
          background: '#f4f4f4',
          borderLeft: '5px solid #ddd',
          padding: '0.5rem 0.5rem',
          marginBottom: '2rem',
        }}
      >
        {article.intro}
      </div>
      {article.authorized ? (
        <MDEditor.Markdown source={article.content} />
      ) : (
        <div style={{ textAlign: 'center' }}>
          <div
            style={{
              color: '#aaa',
              marginBottom: '1rem',
              textAlign: 'left',
            }}
          >
            正文字数: {article.wordsCount}
          </div>
          {article.partialContent && (
            <div style={{ marginBottom: '1rem' }}>
              <MDEditor.Markdown source={article.partialContent} />
              <div
                style={{ marginTop: '1rem', textAlign: 'center', color: 'red' }}
              >
                - 以下还有 90% 内容 -
              </div>
            </div>
          )}
          <div style={{ marginBottom: '1rem' }}>
            <div>
              支付 <span style={{ color: 'red' }}>{article.price} PRS</span>{' '}
              继续阅读
            </div>
            <div>
              并享受早期读者奖励（查看<Link to='/rules'>规则</Link>）
            </div>
          </div>
          <div style={{ marginBottom: '1rem' }}>
            <Alert
              type='warning'
              message='文章为作者在 PRSDigg 平台出售的虚拟商品，一经付款，概不退还。谨慎付款，以防被骗。'
            />
          </div>
          <div>
            {currentUser ? (
              paying ? (
                <Button type='primary' loading disabled danger>
                  支付结果查询中
                </Button>
              ) : (
                <div>
                  <Button type='primary' onClick={handlePaying}>
                    {article.readers.totalCount === 0
                      ? '成为第一位读者'
                      : '付费阅读'}
                  </Button>
                  <div
                    style={{ marginTop: 10, fontSize: '0.8rem', color: '#aaa' }}
                  >
                    已经付款? <a onClick={() => refetch()}>刷新</a> 试试?
                  </div>
                  {mixinEnv && (
                    <div
                      style={{
                        marginTop: 5,
                        fontSize: '0.8rem',
                        color: '#aaa',
                      }}
                    >
                      没有PRS? 去{' '}
                      <a
                        href={`mixin://users/61103d28-3ac2-44a2-ae34-bd956070dab1`}
                      >
                        ExinOne
                      </a>{' '}
                      和{' '}
                      <a
                        href={`mixin://users/a753e0eb-3010-4c4a-a7b2-a7bda4063f62`}
                      >
                        4swap
                      </a>{' '}
                      购买
                    </div>
                  )}
                </div>
              )
            ) : (
              <Button
                type='primary'
                href={`/login?redirect_uri=${encodeURIComponent(
                  location.href,
                )}`}
              >
                请先登录
              </Button>
            )}
          </div>
        </div>
      )}
      <div
        onClick={() => handleShare(article, Boolean(mixinEnv), appId)}
        style={{ margin: '20px 0', textAlign: 'right' }}
      >
        <Button type='link' icon={<ShareAltOutlined />}>
          分享
        </Button>
      </div>
      <div style={{ marginBottom: '2rem' }}>
        <Card>
          <Card.Meta
            avatar={<Avatar src={article.author.avatarUrl} />}
            title={
              <Row style={{ alignItems: 'center' }}>
                <Col style={{ flex: 1 }}>{article.author.name}</Col>
                {(!currentUser ||
                  currentUser.mixinId !== article.author.mixinId) && (
                  <Col>
                    <Button type='primary' shape='round' size='small'>
                      <Link to={`/users/${article.author.mixinId}`}>查看</Link>
                    </Button>
                  </Col>
                )}
              </Row>
            }
            description={article.author.bio || '没有留下介绍'}
          />
        </Card>
      </div>
      <div style={{ marginBottom: '2rem' }}>
        <Row justify='center'>
          <Col>
            {article.authorized &&
            currentUser.mixinId !== article.author.mixinId ? (
              <Button
                type={article.upvoted ? 'primary' : 'default'}
                size='large'
                shape='circle'
                icon={<LikeOutlined />}
                onClick={() => {
                  if (!article.upvoted) {
                    upvoteArticle({
                      variables: { input: { uuid: article.uuid } },
                    });
                  }
                }}
              />
            ) : (
              <Button
                type='primary'
                size='large'
                shape='circle'
                icon={<LikeOutlined />}
              />
            )}
          </Col>
          <Col
            style={{
              marginTop: 10,
              minWidth: 100,
              padding: '0 20px',
              textAlign: 'center',
            }}
          >
            <Progress
              showInfo={false}
              percent={
                (article.upvotesCount /
                  (article.upvotesCount + article.downvotesCount)) *
                100
              }
              strokeColor='#1890ff'
              trailColor={
                article.upvotesCount + article.downvotesCount > 0
                  ? '#ff4d4f'
                  : null
              }
            />
            <div>
              {article.upvotesCount}:{article.downvotesCount}
            </div>
          </Col>
          <Col>
            {article.authorized &&
            currentUser.mixinId !== article.author.mixinId ? (
              <Button
                type={article.downvoted ? 'primary' : 'default'}
                danger={article.downvoted}
                size='large'
                shape='circle'
                icon={<DislikeOutlined />}
                onClick={() => {
                  if (!article.downvoted) {
                    downvoteArticle({
                      variables: { input: { uuid: article.uuid } },
                    });
                  }
                }}
              />
            ) : (
              <Button
                type='primary'
                size='large'
                danger
                shape='circle'
                icon={<DislikeOutlined />}
              />
            )}
          </Col>
        </Row>
      </div>
      {article.authorized && article.author.mixinId !== currentUser.mixinId && (
        <div style={{ marginBottom: '1rem' }}>
          <div style={{ textAlign: 'center' }}>
            <Button
              onClick={() => setRewardModalVisible(true)}
              shape='round'
              type='primary'
              size='large'
              danger
            >
              <HeartOutlined /> 大爱此文
            </Button>
            <Modal
              className='reward-modal'
              centered
              closable={false}
              title='赞赏文章'
              okText='赞赏'
              cancelText='再想想'
              visible={rewardModalVisible}
              onCancel={() => setRewardModalVisible(false)}
              onOk={handleRewarding}
            >
              <Radio.Group
                options={[
                  { label: '1', value: 1 },
                  { label: '8', value: 8 },
                  { label: '32', value: 32 },
                  { label: '64', value: 64 },
                  { label: '256', value: 256 },
                  { label: '1024', value: 1024 },
                ]}
                value={rewardAmount}
                onChange={(e) => setRewardAmount(e.target.value)}
                optionType='button'
              />
            </Modal>
          </div>
        </div>
      )}
      {article.readers.nodes.length > 0 && (
        <div>
          <Row justify='center'>
            <Col>
              <h4>
                <span style={{ color: 'red' }}>
                  {article.buyOrders.totalCount}
                </span>{' '}
                次购买,{' '}
                <span style={{ color: 'red' }}>
                  {article.rewardOrders.totalCount}
                </span>{' '}
                次赞赏
              </h4>
            </Col>
          </Row>
          <Row justify='center' style={{ marginBottom: '1rem' }}>
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
          {article.authorized && (
            <Row gutter={16} style={{ textAlign: 'center' }}>
              <Col xs={12} sm={6}>
                <Statistic title='单价(PRS)' value={article.price} />
              </Col>
              <Col xs={12} sm={6}>
                <Statistic title='付费次数' value={article.ordersCount} />
              </Col>
              <Col xs={12} sm={6}>
                <Statistic
                  title='总收益(PRS)'
                  value={article.revenue ? article.revenue.toFixed(4) : 0.0}
                />
              </Col>
              <Col xs={12} sm={6}>
                <Statistic
                  title='奖励份额(%)'
                  value={
                    article.myShare ? (article.myShare * 100).toFixed(3) : '0.0'
                  }
                />
              </Col>
            </Row>
          )}
        </div>
      )}
      <Divider />
      <CommentsComponent
        commentableType='Article'
        commentableId={article.id}
        authorized={article.authorized}
        commentingSubscribed={article.commentingSubscribed}
        articleUuid={article.uuid}
        refetchArticle={refetch}
      />
    </div>
  );
}
