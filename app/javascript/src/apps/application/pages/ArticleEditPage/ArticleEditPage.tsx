import {
  ArticleQueryHookResult,
  useArticleQuery,
  useUpdateArticleMutation,
} from '@graphql';
import Editor, { commands } from '@uiw/react-md-editor';
import { Button, Form, Input, InputNumber, message, Modal } from 'antd';
import React from 'react';
import { useHistory, useParams } from 'react-router-dom';
import LoadingComponent from '../../components/LoadingComponent/LoadingComponent';

export default function ArticleEditPage() {
  const { uuid } = useParams<{ uuid: string }>();
  const history = useHistory();
  const { data, loading }: ArticleQueryHookResult = useArticleQuery({
    variables: { uuid },
  });
  const [updateArticle, { loading: updating }] = useUpdateArticleMutation({
    update(_, { data: { error: err } }) {
      if (err) {
        message.error(err);
      } else {
        message.success('更新成功');
        history.replace(`/mine`);
      }
    },
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const { article } = data;

  return (
    <Form
      initialValues={{
        uuid,
        title: article.title,
        intro: article.intro,
        content: article.content,
        price: article.price,
      }}
      labelCol={{ span: 2 }}
      wrapperCol={{ span: 22 }}
      onFinish={(values) => {
        const { title, content, price, intro } = values;
        if (!title || !content || !price || !intro) {
          message.warn('请先完成你的文章');
        } else {
          Modal.confirm({
            title: '确定要更新你的文章吗？',
            centered: true,
            okText: '更新',
            cancelText: '再改改',
            onOk: () => updateArticle({ variables: { input: values } }),
          });
        }
      }}
    >
      <Form.Item style={{ display: 'none' }} name='uuid'>
        <Input />
      </Form.Item>
      <Form.Item label='标题' name='title'>
        <Input placeholder='文章标题' />
      </Form.Item>
      <Form.Item label='正文' name='content'>
        <Editor
          textareaProps={{ placeholder: '写点有价值的东西' }}
          autoFocus={false}
          preview='edit'
          placeholder='支持 Markdown 格式'
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
            commands.divider,
            commands.codeEdit,
            commands.codePreview,
          ]}
        />
      </Form.Item>
      <Form.Item label='简介' name='intro'>
        <Input.TextArea placeholder='请简要介绍一下你的文章，简介内容为公开可见。' />
      </Form.Item>
      <Form.Item label='价格(PRS)' name='price'>
        <InputNumber min={1} precision={4} placeholder='0.0' />
      </Form.Item>
      <Form.Item wrapperCol={{ xs: { offset: 0 }, sm: { offset: 2 } }}>
        <Button
          size='large'
          type='primary'
          htmlType='submit'
          loading={updating}
        >
          保存
        </Button>
      </Form.Item>
    </Form>
  );
}
