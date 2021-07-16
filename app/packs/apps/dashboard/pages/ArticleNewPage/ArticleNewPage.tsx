import Editor, { commands } from '@uiw/react-md-editor';
import { MinusCircleOutlined, PlusOutlined } from '@ant-design/icons';
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
  Switch,
} from 'antd';
import EditableTagsComponent from 'apps/dashboard/components/EditableTagsComponent/EditableTagsComponent';
import LoadingComponent from 'apps/dashboard/components/LoadingComponent/LoadingComponent';
import { markdownPreviewOptions, uploadCommand } from 'apps/shared';
import {
  Currency,
  useCreateArticleMutation,
  useMyArticleConnectionQuery,
  usePricableCurrenciesQuery,
} from 'graphqlTypes';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useHistory } from 'react-router-dom';
import UploadComponent from '../../components/UploadComponent/UploadComponent';
import { useDebounce } from 'ahooks';

export default function ArticleNewPage() {
  const history = useHistory();
  const [form] = Form.useForm();
  const { t } = useTranslation();
  const [query, setQuery] = useState('');
  const debouncedQuery = useDebounce(query, { wait: 1000 });
  const { data: availableArticlesData } = useMyArticleConnectionQuery({
    variables: { type: 'available', query: debouncedQuery },
  });
  const [tags, setTags] = useState<string[]>([]);
  const [assetId, setAssetId] = useState(
    'c6d0c728-2624-429b-8e0d-d9d19b6592fa',
  );
  const [price, setPrice] = useState(0.000_001);
  const [referencesEnable, setReferencesEnable] = useState(false);
  const [authorRevenue, setAuthorRevenue] = useState(0.5);
  const { loading, data } = usePricableCurrenciesQuery();
  const [createArticle, { loading: creating }] = useCreateArticleMutation({
    update(_, { data: { createArticle } }) {
      if (createArticle) {
        message.success(t('success_submitted'));
        history.replace('/articles');
      } else {
        message.error(t('please_retry'));
      }
    },
  });

  if (loading) {
    return <LoadingComponent />;
  }
  const { pricableCurrencies } = data;
  const availableArticles =
    availableArticlesData?.myArticleConnection?.nodes || [];

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
        onValuesChange={(_, { articleReferences }) => {
          if (articleReferences) {
            const referencesRevenue = articleReferences.reduce((acc, cur) => {
              return acc + (cur?.revenueRatio || 0);
            }, 0);
            if (referencesRevenue < 0.5) {
              setAuthorRevenue(0.5 - referencesRevenue);
            } else {
              setAuthorRevenue(0);
            }
          }
        }}
        onFinish={(values) => {
          const { title, content, intro, assetId } = values;
          if (!title || !content || !intro || !assetId) {
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
            previewOptions={{ ...markdownPreviewOptions }}
            preview='edit'
            autoFocus={false}
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
          extra={
            price > 0
              ? `≈ $${(currency.priceUsd * price).toFixed(4)}`
              : t('article.form.you_will_create_a_free_article')
          }
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
                    if (
                      currency.symbol === 'BTC' &&
                      (value === 0.0 || value >= 0.000_001)
                    ) {
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
                min={0.0}
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
          label={t('article.form.revenue_distribution')}
          shouldUpdate={(prevValues, curValues) =>
            prevValues.articleReferences !== curValues.articleReferences
          }
        >
          <Form.Item label={t('readers_revenue')}>
            <InputNumber
              disabled
              value={0.4}
              formatter={(value) => `${value * 100}%`}
            />
          </Form.Item>
          <Form.Item label={t('platform_revenue')}>
            <InputNumber
              disabled
              value={0.1}
              formatter={(value) => `${value * 100}%`}
            />
          </Form.Item>
          <Form.Item label={t('author_revenue')}>
            <InputNumber
              disabled
              value={authorRevenue}
              formatter={(value) => `${Math.floor(value * 100)}%`}
            />
          </Form.Item>
          <Form.Item label={t('references_revenue')}>
            <Form.Item>
              <Switch
                checked={referencesEnable}
                onChange={(checked) => {
                  setReferencesEnable(checked);
                  if (!checked) {
                    form.setFieldsValue({ articleReferences: [] });
                    setAuthorRevenue(0.5);
                  }
                }}
              />
            </Form.Item>
            {referencesEnable && (
              <Form.List name='articleReferences'>
                {(references, { add, remove }) => (
                  <>
                    {references.map((reference, index) => (
                      <div
                        className='flex items-baseline w-full space-x-2'
                        key={index}
                      >
                        <Form.Item noStyle>
                          <Form.Item
                            {...reference}
                            className='flex-1'
                            fieldKey={[reference.fieldKey, 'referenceId']}
                            name={[reference.name, 'referenceId']}
                            label={t('article.article_text')}
                            rules={[
                              {
                                required: true,
                                message: t(
                                  'article.form.please_select_an_article',
                                ),
                              },
                            ]}
                          >
                            <Select
                              allowClear
                              showSearch
                              filterOption={false}
                              onSearch={(value: string) => setQuery(value)}
                              onChange={() => setQuery('')}
                              options={availableArticles.map((article) => {
                                return {
                                  label: (
                                    <div className='flex flex-wrap items-center space-x-2'>
                                      <img
                                        className='w-6 h-6 rounded-full'
                                        src={article.author.avatar}
                                      />
                                      <span>{article.author.name}:</span>
                                      <span>{article.title}</span>
                                    </div>
                                  ),
                                  value: article.uuid,
                                };
                              })}
                            />
                          </Form.Item>
                        </Form.Item>
                        <Form.Item
                          className='flex-1'
                          {...reference}
                          fieldKey={[reference.fieldKey, 'revenueRatio']}
                          name={[reference.name, 'revenueRatio']}
                          rules={[
                            {
                              required: true,
                              message: t(
                                'article.form.please_input_revenue_ratio',
                              ),
                            },
                            {
                              validator: () => {
                                const articleReferences =
                                  form.getFieldValue('articleReferences');
                                const referencesRevenue =
                                  articleReferences?.reduce((acc, cur) => {
                                    return acc + (cur?.revenueRatio || 0);
                                  }, 0);
                                if (
                                  referencesRevenue &&
                                  referencesRevenue >= 0.5
                                ) {
                                  return Promise.reject(
                                    new Error(
                                      t(
                                        'article.form.references_revenue_cannot_larger_than_50%',
                                      ),
                                    ),
                                  );
                                } else {
                                  return Promise.resolve();
                                }
                              },
                            },
                          ]}
                          label={t('article.form.revenue_ratio')}
                        >
                          <InputNumber
                            min={0.01}
                            max={0.49}
                            step='0.01'
                            formatter={(value: number) => `${value * 100}%`}
                            parser={(value) =>
                              parseInt(value.replace('%', '')) / 100.0
                            }
                          />
                        </Form.Item>
                        <MinusCircleOutlined
                          onClick={() => remove(reference.name)}
                        />
                      </div>
                    ))}
                    <Form.Item>
                      <Button
                        type='dashed'
                        disabled={references.length >= 10}
                        onClick={() =>
                          references.length < 10 && add({ revenueRatio: 0.05 })
                        }
                        block
                        icon={<PlusOutlined />}
                      >
                        {t('article.form.add_reference')}
                      </Button>
                    </Form.Item>
                  </>
                )}
              </Form.List>
            )}
          </Form.Item>
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
