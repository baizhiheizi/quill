import { HeartOutlined, ShareAltOutlined } from '@ant-design/icons';
import { ArticleQueryHookResult, useArticleQuery, User } from '@graphql';
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
import CommentsComponent from '../../components/CommentsComponent/CommentsComponent';
import LoadingComponent from '../../components/LoadingComponent/LoadingComponent';
import {
  handleShare,
  PAGE_TITLE,
  useCurrentUser,
  useMixin,
  usePrsdigg,
} from '../../shared';
import NotFoundPage from '../NotFoundPage/NotFoundPage';
import './ArticlePage.less';

let traceId: string;
export default function ArticlePage() {
  const { uuid } = useParams<{ uuid: string }>();
  const [paying, setPaying] = useState(false);
  const [rewardModalVisible, setRewardModalVisible] = useState(false);
  const [rewardAmount, setRewardAmount] = useState(1);
  const { appId } = usePrsdigg();
  const { mixinEnv } = useMixin();
  const currentUser = useCurrentUser();
  const { loading, data, refetch }: ArticleQueryHookResult = useArticleQuery({
    fetchPolicy: 'network-only',
    variables: { uuid },
  });

  useEffect(() => {
    traceId = uuidv4();
    return () => (document.title = PAGE_TITLE);
  }, [uuid]);

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

  if (!article) {
    return <NotFoundPage />;
  }

  document.title = `${article.title} - ${article.author.name}`;

  const handlePaying = () => {
    if (mixinEnv) {
      setPaying(true);
      const payUrl = `mixin://pay?recipient=${appId}&trace=${traceId}&memo=${memo}&asset=${
        article.assetId
      }&amount=${article.price.toFixed(8)}`;
      location.replace(payUrl);
    } else {
      message.warn('请在 Mixin Messenger 中付款');
    }
  };
  const handlePaid = () => {
    refetch();
    setPaying(false);
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
                <Button onClick={handlePaid}>支付完成</Button>
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
      <div style={{ marginBottom: '1rem' }}>
        <Card>
          <Card.Meta
            avatar={<Avatar src={article.author.avatarUrl} />}
            title={article.author.name}
            description={article.author.bio || '没有留下介绍'}
          />
        </Card>
      </div>
      {article.authorized && article.author.mixinId !== currentUser.mixinId && (
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
      )}
      {article.readers.nodes.length > 0 && (
        <div>
          <Divider />
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
      />
    </div>
  );
}
