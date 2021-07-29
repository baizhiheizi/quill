# 顶瓜瓜

![Check](https://github.com/baizhiheizi/prsdigg/workflows/Check/badge.svg) ![CI](https://github.com/baizhiheizi/prsdigg/workflows/CI/badge.svg) ![Uptime 100.00%](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fbaizhiheizi%2Fupptime%2Fmaster%2Fapi%2Fprs-digg%2Fuptime.json) ![Response Time](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fbaizhiheizi%2Fupptime%2Fmaster%2Fapi%2Fprs-digg%2Fresponse-time.json)

[English](README.md)

---

## 应用截图

![snapshot](snapshot.png)

---

顶瓜瓜 是建立于[Mixin Network](https://mixin.one) 之上的 Dapp。所有支付以及转账则通过 [Mixin Network](https://mixin.one) 完成。

## 规则

顶瓜瓜 尝试建立一个**作者**与**读者**共赢的**平台**。

我们认为，一篇文章产生的价值是由作者和读者共同构成的，但是实际情况是，读者的付出并没有得到很好体现，尤其是**早期读者**。因此，与其他平台最大的不同是，顶瓜瓜 引入**早期读者奖励**的机制。

具体的规则如下：

1. 用户可以在**平台**上发布文章，成为**作者**；

2. 所有文章均为付费文章，使用*PressOne Token* 或者 *Bitcoin* 计价；

3. 用户可以付费购买文章，即成为文章的**读者**；

4. 文章每获得一笔新收入，其中 40% 将作为**早期读者奖励**，按付费比例分配给每一位**早期读者**，10% 将作为**平台**的手续费，剩余部分作为**作者**的收益；

5. **读者**也可以通过打赏的手段增加对某篇文章的付费，以提高自己在奖励中的分配比例。

举个例子：

用户 A 在平台上发布了一篇文章 X 定价 100 聪 BTC。

用户 B 付费 100 聪 购买了文章 X，获得了文章的阅读权。

文章 X 因此获得 100 聪 的收入，因为 B 是第一位读者，没有更早期的读者，所以没有早期读者奖励；其中 10 聪（10%）作为平台的手续费；剩余 90 聪 全部作为作者收益，转入作者 A 的账号。

用户 C 在 B 之后付费 100 聪 购买了文章 X，文章 X 因此再次获得 100 聪 的收入。

其中 40 聪（40%）将作为早期读者奖励，这时早期读者只有用户 B 一人，所以 B 独占了这 40% 的奖励；平台同样收取 10 聪（10%）作为手续费；剩余 50 聪 作为作者收益。

在 C 之后，用户 D 同样付费 100 聪 购买了文章 X。

同样地，有 40 聪（40%）将作为早期读者奖励，这时的早期读者有两人，即 B 和 C，二人此前为文章 X 各自付费了 100 聪，因此 B 和 C 都将分别得到 \`4 * 100 / (100 + 100) = 2\` 聪 的奖励。

平台同样收取 10 聪（10%）作为手续费；剩余 50 聪 作为作者收益。

以此类推。

值得提醒的是，除了购买文章的付费，其他付费行为（例如打赏）的付费，也会计入早期读者奖励的分配比例。

## 体验

目前 顶瓜瓜 仅支持 [Mixin Messenger](https://mixin.one/messenger) 登录以及完成支付，体验前先下载安装。

浏览 [prsdigg.com](https://prsdigg.com) ，或者在 [Mixin Messenger](https://mixin.one/messenger) 中搜索 7000101549 即可体验。
