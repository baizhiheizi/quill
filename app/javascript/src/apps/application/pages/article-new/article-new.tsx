import { useCreateArticleMutation } from '@/graphql';
import Editor, { commands } from '@uiw/react-md-editor';
import { Button, Form, Input, InputNumber, message } from 'antd';
import React from 'react';
import { useHistory } from 'react-router-dom';

export function ArticleNew() {
  const history = useHistory();
  const [createArticle, { loading }] = useCreateArticleMutation({
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
        message.success('Created!');
        history.replace('/');
      }
    },
  });
  return (
    <Form
      labelCol={{ span: 2 }}
      wrapperCol={{ span: 22 }}
      onFinish={(values) => createArticle({ variables: { input: values } })}
    >
      <Form.Item
        label='标题'
        name='title'
        rules={[{ required: true, message: '请填写标题' }]}
      >
        <Input placeholder='文章标题' />
      </Form.Item>
      <Form.Item
        label='正文'
        name='content'
        rules={[{ required: true, message: '请填写正文' }]}
      >
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
          ]}
        />
      </Form.Item>
      <Form.Item
        label='简介'
        name='intro'
        rules={[{ required: true, message: '请填写一段简介' }]}
      >
        <Input.TextArea placeholder='请简要介绍一下你的文章，简介内容为公开可见。' />
      </Form.Item>
      <Form.Item
        label='Price'
        name='price'
        rules={[{ required: true, message: '你的文章应该有价格' }]}
      >
        <InputNumber min={1} precision={4} placeholder='1.0' />
        <span style={{ marginLeft: 10 }}>PRS</span>
      </Form.Item>
      <Form.Item wrapperCol={{ xs: { offset: 0 }, sm: { offset: 2 } }}>
        <Button type='primary' htmlType='submit' loading={loading}>
          发布
        </Button>
      </Form.Item>
    </Form>
  );
}
