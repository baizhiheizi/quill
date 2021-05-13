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
  Radio,
  Select,
  Space,
} from 'antd';
import EditableTagsComponent from 'apps/dashboard/components/EditableTagsComponent/EditableTagsComponent';
import LoadingComponent from 'apps/dashboard/components/LoadingComponent/LoadingComponent';
import { markdownPlugins, markdownRenderers, uploadCommand } from 'apps/shared';
import {
  Currency,
  useCreateArticleMutation,
  usePricableCurrenciesQuery,
} from 'graphqlTypes';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useHistory } from 'react-router-dom';
import UploadComponent from '../../components/UploadComponent/UploadComponent';

export default function ArticleNewPage() {
  const history = useHistory();
  const [form] = Form.useForm();
  const { t } = useTranslation();
  const [tags, setTags] = useState<string[]>([]);
  const [assetId, setAssetId] = useState(
    'c6d0c728-2624-429b-8e0d-d9d19b6592fa',
  );
  const [price, setPrice] = useState(0.000_001);
  const { loading, data } = usePricableCurrenciesQuery();
  const [createArticle, { loading: creating }] = useCreateArticleMutation({
    update(
      _,
      {
        data: {
          createArticle: { error },
        },
      },
    ) {
      if (error) {
        message.error(error);
      } else {
        message.success(t('success_submitted'));
        history.replace('/articles');
      }
    },
  });

  if (loading) {
    return <LoadingComponent />;
  }
  const { pricableCurrencies } = data;
  const currency = pricableCurrencies.find(
    (_currency: Currency) => _currency.assetId === assetId,
  );
  return (
    <div>
      <PageHeader
        title={t('new_article')}
        breadcrumb={{
          routes: [
            { path: '/articles', breadcrumbName: t('articles_manage') },
            { path: '', breadcrumbName: t('new_article') },
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
          assetId,
          content: '',
          price,
          state: 'published',
        }}
        labelCol={{ span: 2 }}
        wrapperCol={{ span: 22 }}
        onFinish={(values) => {
          const { title, content, price, intro, assetId } = values;
          if (!title || !content || !price || !intro || !assetId) {
            message.warn(t('article.form.not_finished'));
          } else {
            Modal.confirm({
              title: t('article.form.confirm_to_create'),
              centered: true,
              okText: t('create'),
              cancelText: t('later'),
              onOk: () =>
                createArticle({
                  variables: { input: { ...values, tagNames: tags } },
                }),
            });
          }
        }}
      >
        <Form.Item
          label={t('article.title')}
          name='title'
          rules={[
            { required: true, message: t('article.form.title_is_required') },
          ]}
        >
          <Input placeholder={t('article.form.title_place_holder')} />
        </Form.Item>
        <Form.Item
          label={t('article.content')}
          name='content'
          rules={[
            { required: true, message: t('article.form.content_is_required') },
          ]}
        >
          <Editor
            textareaProps={{
              placeholder: t('article.form.content_place_holder'),
            }}
            previewOptions={{
              plugins: markdownPlugins,
              renderers: markdownRenderers,
            }}
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
        <Form.Item
          label={t('article.intro')}
          name='intro'
          rules={[
            { required: true, message: t('article.form.intro_is_required') },
          ]}
        >
          <Input.TextArea placeholder={t('article.form.intro_place_holder')} />
        </Form.Item>
        <Form.Item label={t('article.tags')}>
          <EditableTagsComponent tags={tags} setTags={setTags} />
        </Form.Item>
        <Form.Item
          label={t('article.price')}
          extra={`≈ $${(currency.priceUsd * price).toFixed(4)}`}
        >
          <Space>
            <Form.Item
              name='price'
              noStyle
              dependencies={['assetId']}
              rules={[
                { required: true },
                {
                  validator: (_, value) => {
                    if (currency.symbol === 'BTC' && value >= 0.000_001) {
                      return Promise.resolve();
                    } else if (currency.symbol === 'PRS' && value >= 1) {
                      return Promise.resolve();
                    } else {
                      return Promise.reject(t('article.form.price_is_too_low'));
                    }
                  },
                },
              ]}
            >
              <InputNumber
                onChange={(value) => setPrice(parseFloat(value.toString()))}
                style={{ minWidth: 130 }}
                min={0.000_001}
                step='0.000001'
                precision={6}
                placeholder='0.0'
              />
            </Form.Item>
            <Form.Item name='assetId' noStyle rules={[{ required: true }]}>
              <Select onSelect={(value: string) => setAssetId(value)}>
                {pricableCurrencies.map((_currency: Currency) => (
                  <Select.Option
                    key={_currency.assetId}
                    value={_currency.assetId}
                  >
                    <Space>
                      <Avatar size='small' src={_currency.iconUrl} />
                      {_currency.symbol}
                    </Space>
                  </Select.Option>
                ))}
              </Select>
            </Form.Item>
          </Space>
        </Form.Item>
        <Form.Item
          label={t('article.state_text')}
          name='state'
          rules={[{ required: true }]}
        >
          <Radio.Group
            options={[
              { label: t('article.state.published'), value: 'published' },
              { label: t('article.state.hidden'), value: 'hidden' },
            ]}
          />
        </Form.Item>
        <Form.Item wrapperCol={{ xs: { offset: 0 }, sm: { offset: 2 } }}>
          <Button
            size='large'
            type='primary'
            htmlType='submit'
            loading={creating}
          >
            {t('create')}
          </Button>
        </Form.Item>
      </Form>
    </div>
  );
}
