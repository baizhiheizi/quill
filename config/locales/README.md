# How to translate

## Preparation

There are 3 groups of files in this folder, they are:

- models.*.yml
- notifications.*.yml
- views.*.yml

in which, the '*' indicates the locale name.

At present, PrsDigg supports three locale name, they are `en` (English, default), `zh-CN`, and `ja`.

If you want to participate in the translation, simply fork this repo and modify the files.

## Translate

The format of the translation files is called `YAML`. It's a simple plain-text file format.

For example, the content of file 'models.ja.yml' is:

```
en:
  created_at: Created At
  updated_at: Updated At
  article:
    title: タイトル
    content: コンテンツ
    intro: 前書き
    currency: 通貨
    words_count: Words Count
    price: Price
    upvotes_count: Upvotes

...

```

Most words, sentences and text in the file are arrange as `Key: Value` format. Please translate the text before ":" symbol.