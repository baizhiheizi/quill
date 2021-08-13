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
import { markdownPreviewOptions, uploadCommand } from 'apps/shared';
import { Article, useUpdateArticleMutation } from 'graphqlTypes';
import moment from 'moment';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useHistory } from 'react-router-dom';
import EditableTagsComponent from '../../components/EditableTagsComponent/EditableTagsComponent';

export default function PublishedArticleEditComponent(props: {
  article: Partial<Article>;
}) {
  const { article } = props;
  const [form] = Form.useForm();
  const [editedPrice, setEditedPrice] = useState(0);
  const history = useHistory();
  const { t } = useTranslation();
  const [tags, setTags] = useState<string[]>(article.tagNames || []);
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
        history.replace(`/articles/${article.uuid}`);
      }
    },
  });

  return (
    <>
      <PageHeader
        title={t('edit_article')}
        breadcrumb={{
          routes: [
            { path: '/articles', breadcrumbName: t('articles_manage') },
            {
              path: `/articles/${article.uuid}`,
              breadcrumbName:
                article.title ||
                moment(article.createdAt).format('YYYY-MM-DD HH:MM'),
            },
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
      <Form
        form={form}
        initialValues={{
          uuid: article.uuid,
          title: article.title,
          intro: article.intro,
          content: article.content,
          price: article.price,
          assetId: article.assetId,
        }}
        labelCol={{ span: 4 }}
        wrapperCol={{ span: 20 }}
        onFinish={(values) => {
          const { uuid, title, content, price, intro } = values;
          if (
            !title ||
            !content ||
            (price !== article.price && !price) ||
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
            article.currency.priceUsd * (editedPrice || article.price)
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
                      article.currency.symbol === 'BTC' &&
                      value >= 0.000_001
                    ) {
                      return Promise.resolve();
                    } else if (article.price == value) {
                      return Promise.resolve();
                    } else {
                      return Promise.reject(t('article.form.price_is_too_low'));
                    }
                  },
                },
              ]}
            >
              <InputNumber
                disabled={article.price === 0.0}
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
                  key={article.currency.assetId}
                  value={article.currency.assetId}
                >
                  <Space>
                    <Avatar size='small' src={article.currency.iconUrl} />
                    {article.currency.symbol}
                  </Space>
                </Select.Option>
              </Select>
            </Form.Item>
          </Space>
        </Form.Item>
        <Form.Item label={t('readers_revenue')}>
          <InputNumber
            disabled
            value={article.readersRevenueRatio}
            formatter={(value) => `${value * 100}%`}
          />
        </Form.Item>
        <Form.Item label={t('platform_revenue')}>
          <InputNumber
            disabled
            value={article.platformRevenueRatio}
            formatter={(value) => `${value * 100}%`}
          />
        </Form.Item>
        <Form.Item label={t('author_revenue')}>
          <InputNumber
            disabled
            value={article.authorRevenueRatio}
            formatter={(value) => `${Math.floor(value * 100)}%`}
          />
        </Form.Item>
        {article.articleReferences.length > 0 && (
          <Form.Item label={t('article_references')}>
            {article.articleReferences.map((articleReference) => (
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
        <Form.Item wrapperCol={{ xs: { offset: 0 }, sm: { offset: 4 } }}>
          <Button type='primary' htmlType='submit' loading={updating}>
            {t('update')}
          </Button>
        </Form.Item>
      </Form>
    </>
  );
}
