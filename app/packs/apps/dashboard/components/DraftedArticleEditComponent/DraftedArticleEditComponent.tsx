import { MinusCircleOutlined, PlusOutlined } from '@ant-design/icons';
import Editor, { commands } from '@uiw/react-md-editor';
import { useDebounce, useDebounceFn } from 'ahooks';
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
  Spin,
  Switch,
} from 'antd';
import EditableTagsComponent from 'apps/dashboard/components/EditableTagsComponent/EditableTagsComponent';
import LoadingComponent from 'apps/dashboard/components/LoadingComponent/LoadingComponent';
import { markdownPreviewOptions, uploadCommand } from 'apps/shared';
import {
  Article,
  Currency,
  useMyArticleConnectionQuery,
  usePricableCurrenciesQuery,
  usePublishArticleMutation,
  useUpdateArticleMutation,
} from 'graphqlTypes';
import moment from 'moment';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useHistory } from 'react-router-dom';

export default function DraftedArticleEditComponent(props: {
  article: Partial<Article>;
}) {
  const { article } = props;
  const { t, i18n } = useTranslation();
  const history = useHistory();
  const [form] = Form.useForm();
  const [tags, setTags] = useState<string[]>(article.tagNames || []);
  const [publishModalVisible, setPublishModalVisible] = useState(false);
  moment.locale(i18n.language);

  const [updateArticle, { loading: updating }] = useUpdateArticleMutation({
    onError: () => {
      message.error(t('failed_to_save'));
    },
  });
  const { run: debouncedUpdateArticle } = useDebounceFn(
    () =>
      updateArticle({
        variables: {
          input: {
            uuid: article.uuid,
            content: form.getFieldValue('content'),
            title: form.getFieldValue('title'),
            intro: form.getFieldValue('intro'),
            tagNames: tags,
          },
        },
      }),
    { wait: 1000 },
  );

  return (
    <>
      <PageHeader
        title={t('write')}
        subTitle={
          updating ? (
            <Spin size='small' />
          ) : (
            <span className='p-2 text-xs bg-gray-200 rounded'>{`${moment(
              article.updatedAt,
            ).format('HH:MM:ss')} ${t('saved')}`}</span>
          )
        }
        extra={[
          <Button
            key='publish'
            type='primary'
            onClick={() => {
              form
                .validateFields()
                .then(() => setPublishModalVisible(true))
                .catch(() => message.warn(t('article.form.not_finished')));
            }}
          >
            {t('publish')}
          </Button>,
        ]}
        breadcrumb={{
          routes: [
            { path: '/articles', breadcrumbName: t('articles_manage') },
            { path: '', breadcrumbName: t('write') },
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
          title: article.title,
          content: article.content,
          intro: article.intro,
        }}
        labelCol={{ span: 2 }}
        wrapperCol={{ span: 22 }}
        onValuesChange={() => debouncedUpdateArticle()}
      >
        <Form.Item
          label={t('article.title')}
          name='title'
          rules={[
            { required: true, message: t('article.form.title_is_required') },
            { max: 64, message: t('article.form.title_is_too_long') },
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
            height={700}
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
            { max: 140, message: t('article.form.intro_is_too_long') },
          ]}
        >
          <Input.TextArea placeholder={t('article.form.intro_place_holder')} />
        </Form.Item>
        <Form.Item label={t('article.tags')}>
          <EditableTagsComponent
            tags={tags}
            setTags={(values) => {
              setTags(values);
              debouncedUpdateArticle();
            }}
          />
        </Form.Item>
      </Form>
      <Modal
        title={t('publish_article')}
        visible={publishModalVisible}
        onCancel={() => setPublishModalVisible(false)}
        width={768}
        centered
        footer={null}
      >
        <PublishArticleForm article={article} />
      </Modal>
    </>
  );
}

function PublishArticleForm(props: { article: Partial<Article> }) {
  const { article } = props;
  const { t } = useTranslation();
  const history = useHistory();
  const [form] = Form.useForm();
  const [assetId, setAssetId] = useState(article.assetId);
  const [price, setPrice] = useState(article.price);
  const [referencesEnable, setReferencesEnable] = useState(false);
  const [query, setQuery] = useState('');
  const debouncedQuery = useDebounce(query, { wait: 1000 });
  const [authorRevenue, setAuthorRevenue] = useState(0.5);
  const { loading, data } = usePricableCurrenciesQuery();
  const { data: availableArticlesData } = useMyArticleConnectionQuery({
    variables: { type: 'available', query: debouncedQuery },
  });
  const [publishArticle, { loading: publishing }] = usePublishArticleMutation({
    update: (_, { data: { publishArticle: res } }) => {
      if (res) {
        history.replace(`/articles/${article.uuid}`);
      } else {
        message.error(t('failed_to_publish'));
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
    <>
      <Form
        form={form}
        initialValues={{
          assetId,
          price,
        }}
        labelCol={{ span: 4 }}
        wrapperCol={{ span: 20 }}
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
          Modal.confirm({
            title: t('confirm_to_publish'),
            centered: true,
            okText: t('publish'),
            cancelText: t('later'),
            onOk: () =>
              publishArticle({
                variables: { input: { ...values, uuid: article.uuid } },
              }),
          });
        }}
      >
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
          noStyle
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
                        className='flex flex-wrap items-baseline w-full space-x-2'
                        key={index}
                      >
                        <Form.Item noStyle>
                          <Form.Item
                            {...reference}
                            className='flex-1 flex-nowrap'
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
                                    <div className='flex items-center truncate flex-nowrap space-x-2'>
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
        <Form.Item wrapperCol={{ xs: { offset: 0 }, sm: { offset: 4 } }}>
          <Button type='primary' htmlType='submit' loading={publishing}>
            {t('create')}
          </Button>
        </Form.Item>
      </Form>
    </>
  );
}
