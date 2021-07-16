import Editor, { commands } from '@uiw/react-md-editor';
import {
  Avatar,
  Button,
  Form,
  Input,
  InputNumber,
  message,
  Modal,
  PageHeader,
  Select,
  Space,
} from 'antd';
import LoadingComponent from 'apps/dashboard/components/LoadingComponent/LoadingComponent';
import { markdownPreviewOptions, uploadCommand } from 'apps/shared';
import { useMyArticleQuery, useUpdateArticleMutation } from 'graphqlTypes';
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useHistory, useParams } from 'react-router-dom';
import EditableTagsComponent from '../../components/EditableTagsComponent/EditableTagsComponent';
import UploadComponent from '../../components/UploadComponent/UploadComponent';

export default function ArticleEditPage() {
  const { uuid } = useParams<{ uuid: string }>();
  const [form] = Form.useForm();
  const [editedPrice, setEditedPrice] = useState(0);
  const history = useHistory();
  const { t } = useTranslation();
  const [tags, setTags] = useState<string[]>([]);
  const { data, loading } = useMyArticleQuery({
    fetchPolicy: 'network-only',
    variables: { uuid },
  });
  const [updateArticle, { loading: updating }] = useUpdateArticleMutation({
    update(
      _,
      {
        data: {
          updateArticle: { error: err },
        },
      },
    ) {
      if (err) {
        message.error(err);
      } else {
        message.success(t('success_submitted'));
        history.replace(`/articles/${uuid}`);
      }
    },
  });

  useEffect(() => {
    setTags(data?.myArticle?.tagNames || []);
  }, [data]);

  if (loading) {
    return <LoadingComponent />;
  }

  const { myArticle } = data;

  return (
    <div>
      <PageHeader
        title={t('edit_article')}
        breadcrumb={{
          routes: [
            { path: '/articles', breadcrumbName: t('articles_manage') },
            { path: `/articles/${uuid}`, breadcrumbName: myArticle.title },
            { path: '', breadcrumbName: t('edit_article') },
          ],
          itemRender: (route, _params, routes, _paths) => {
            const last = routes.indexOf(route) === routes.length - 1;
            return last ? (
              <span>{route.breadcrumbName}</span>
            ) : (
              <Link to={route.path}>{route.breadcrumbName}</Link>
            );
          },
        }}
      />
      <UploadComponent
        callback={(blob) => {
          form.setFieldsValue({
            content: `${form.getFieldValue('content')}\n![${blob.filename}](${
              blob.url
            })\n`,
          });
        }}
      />
      <Form
        form={form}
        initialValues={{
          uuid,
          title: myArticle.title,
          intro: myArticle.intro,
          content: myArticle.content,
          price: myArticle.price,
          assetId: myArticle.assetId,
        }}
        labelCol={{ span: 2 }}
        wrapperCol={{ span: 22 }}
        onFinish={(values) => {
          const { uuid, title, content, price, intro } = values;
          if (
            !title ||
            !content ||
            (price !== myArticle.price && !price) ||
            !intro
          ) {
            message.warn(t('article.form.not_finished'));
          } else {
            Modal.confirm({
              title: t('article.form.confirm_to_update'),
              centered: true,
              okText: t('update'),
              cancelText: t('later'),
              onOk: () =>
                updateArticle({
                  variables: {
                    input: {
                      uuid,
                      title,
                      content,
                      price,
                      intro,
                      tagNames: tags,
                    },
                  },
                }),
            });
          }
        }}
      >
        <Form.Item style={{ display: 'none' }} name='uuid'>
          <Input />
        </Form.Item>
        <Form.Item label={t('article.title')} name='title'>
          <Input placeholder={t('article.form.title_place_holder')} />
        </Form.Item>
        <Form.Item label={t('article.content')} name='content'>
          <Editor
            textareaProps={{
              placeholder: t('article.form.content_place_holder'),
            }}
            previewOptions={{ ...markdownPreviewOptions }}
            autoFocus={false}
            preview='edit'
            height={500}
            commands={[
              commands.bold,
              commands.italic,
              commands.quote,
              commands.hr,
              commands.title,
              commands.divider,
              commands.link,
              commands.code,
              uploadCommand,
              commands.divider,
              commands.codeEdit,
              commands.codePreview,
            ]}
          />
        </Form.Item>
        <Form.Item label={t('article.intro')} name='intro'>
          <Input.TextArea placeholder={t('article.form.intro_place_holder')} />
        </Form.Item>
        <Form.Item label={t('article.tags')}>
          <EditableTagsComponent tags={tags} setTags={setTags} />
        </Form.Item>
        <Form.Item
          label={t('article.price')}
          extra={`≈ $${(
            myArticle.currency.priceUsd * (editedPrice || myArticle.price)
          ).toFixed(4)}`}
        >
          <Space>
            <Form.Item
              name='price'
              noStyle
              rules={[
                { required: true },
                {
                  validator: (_, value) => {
                    if (
                      myArticle.currency.symbol === 'BTC' &&
                      value >= 0.000_001
                    ) {
                      return Promise.resolve();
                    } else if (myArticle.price == value) {
                      return Promise.resolve();
                    } else {
                      return Promise.reject(t('article.form.price_is_too_low'));
                    }
                  },
                },
              ]}
            >
              <InputNumber
                disabled={myArticle.price === 0.0}
                onChange={(value) =>
                  setEditedPrice(parseFloat(value.toString()))
                }
                style={{ minWidth: 130 }}
                min={0.000_001}
                step='0.000001'
                precision={6}
                placeholder='0.0'
              />
            </Form.Item>
            <Form.Item name='assetId' noStyle rules={[{ required: true }]}>
              <Select disabled>
                <Select.Option
                  key={myArticle.currency.assetId}
                  value={myArticle.currency.assetId}
                >
                  <Space>
                    <Avatar size='small' src={myArticle.currency.iconUrl} />
                    {myArticle.currency.symbol}
                  </Space>
                </Select.Option>
              </Select>
            </Form.Item>
          </Space>
        </Form.Item>
        <Form.Item label={t('article.form.revenue_distribution')}>
          <Form.Item label={t('readers_revenue')}>
            <InputNumber
              disabled
              value={myArticle.readersRevenueRatio}
              formatter={(value) => `${value * 100}%`}
            />
          </Form.Item>
          <Form.Item label={t('platform_revenue')}>
            <InputNumber
              disabled
              value={myArticle.platformRevenueRatio}
              formatter={(value) => `${value * 100}%`}
            />
          </Form.Item>
          <Form.Item label={t('author_revenue')}>
            <InputNumber
              disabled
              value={myArticle.authorRevenueRatio}
              formatter={(value) => `${Math.floor(value * 100)}%`}
            />
          </Form.Item>
          {myArticle.articleReferences.length > 0 && (
            <Form.Item label={t('article_references')}>
              {myArticle.articleReferences.map((articleReference) => (
                <Form.Item key={articleReference.reference.uuid}>
                  <div className='flex flex-wrap items-center'>
                    <Avatar
                      className='mr-2'
                      size='small'
                      src={articleReference.reference.author.avatar}
                    />
                    <span className='mr-2'>
                      {articleReference.reference.author.name}:
                    </span>
                    <a
                      href={`/articles/${articleReference.reference.uuid}`}
                      target='_blank'
                    >
                      {articleReference.reference.title}
                    </a>
                    <div className='ml-auto text-blue-500'>
                      {articleReference.revenueRatio * 100}%
                    </div>
                  </div>
                </Form.Item>
              ))}
            </Form.Item>
          )}
        </Form.Item>
        <Form.Item wrapperCol={{ xs: { offset: 0 }, sm: { offset: 2 } }}>
          <Button type='primary' htmlType='submit' loading={updating}>
            {t('update')}
          </Button>
        </Form.Item>
      </Form>
    </div>
  );
}
