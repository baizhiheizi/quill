# PRSDigg

![Check](https://github.com/baizhiheizi/prsdigg/workflows/Check/badge.svg) ![CI](https://github.com/baizhiheizi/prsdigg/workflows/CI/badge.svg) ![Uptime 100.00%](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fbaizhiheizi%2Fupptime%2Fmaster%2Fapi%2Fprs-digg%2Fuptime.json) ![Response Time](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fbaizhiheizi%2Fupptime%2Fmaster%2Fapi%2Fprs-digg%2Fresponse-time.json)

PRSDigg 是建立于 [PRESSone](https://press.one) 与 [Mixin Network](https://mixin.one) 之上的 Dapp。发表于 PRSDigg 上的文章将全部在 [PRESSone](https://press.one) 签名上链，所有支付以及转账则通过 [Mixin Network](https://mixin.one) 完成。

## 规则

PRSDigg 尝试建立一个**作者**与**读者**共赢的**平台**。

我们认为，一篇文章产生的价值是由作者和读者共同构成的，但是实际情况是，读者的付出并没有得到很好体现，尤其是**早期读者**。因此，与其他平台最大的不同是，PRSDigg 引入**早期读者奖励**的机制。

具体的规则如下：

1. 用户可以在**平台**上发布文章，成为**作者**；

2. 所有文章均为付费文章，使用*PressOne Token*计价，最低 1 PRS；

3. 用户可以付费购买文章，即成为文章的**读者**；

4. 文章每获得一笔新收入，其中 40% 将作为**早期读者奖励**，按付费比例分配给每一位**早期读者**，10% 将作为**平台**的手续费，剩余部分作为**作者**的收益；

5. **读者**也可以通过打赏的手段增加对某篇文章的付费，以提高自己在奖励中的分配比例。

举个例子：

用户 A 在平台上发布了一篇文章 X 定价 10 PRS。

用户 B 付费 10 PRS 购买了文章 X，获得了文章的阅读权。

文章 X 因此获得 10 PRS 的收入，因为 B 是第一位读者，没有更早期的读者，所以没有早期读者奖励；其中 1 PRS（10%）作为平台的手续费；剩余 9 PRS 全部作为作者收益，转入作者 A 的账号。

用户 C 在 B 之后付费 10 PRS 购买了文章 X，文章 X 因此再次获得 10 PRS 的收入。

其中 4 PRS（40%）将作为早期读者奖励，这时早期读者只有用户 B 一人，所以 B 独占了这 40% 的奖励；平台同样收取 1 PRS（10%）作为手续费；剩余 5 PRS 作为作者收益。

在 C 之后，用户 D 同样付费 10 PRS 购买了文章 X。

同样地，有 4 PRS（40%）将作为早期读者奖励，这时的早期读者有两人，即 B 和 C，二人此前为文章 X 各自付费了 10 PRS，因此 B 和 C 都将分别得到 \`4 * 10 / (10 + 10) = 2\` PRS 的奖励。

平台同样收取 1 PRS（10%）作为手续费；剩余 5 PRS 作为作者收益。

以此类推。

值得提醒的是，除了购买文章的付费，其他付费行为（例如打赏）的付费，也会计入早期读者奖励的分配比例。

## 体验

目前 PRSDigg 仅支持 [Mixin Messenger](https://mixin.one/messenger) 登录以及完成支付，体验前先下载安装。

浏览 [prsdigg.com](https://prsdigg.com) ，或者在 [Mixin Messenger](https://mixin.one/messenger) 中搜索 7000101549 即可体验。

----

## PRSDigg  

PRSDigg is a Dapp built on [PRESSONE](https://press.one/) and [Mixin Network](https://mixin.one/). All articles published on PRSDigg will be signed up at [PRESSONE](https:/press.one/) and all payments and transfers will be completed through  [Mixin Network](https://mixin.one/). 

## Rules

PRSDigg tries to build a win-win **platform  ** for both **authors** and **readers**.

We believe that the value of an article is composed of both the author and the reader, but the actual situation is that the reader's contribution, especially the early readers' contribution,is not well represented. Therefore, the biggest difference between PRSDigg and other platforms is that PRSDigg introduces an **early reader rewards** mechanism.

The specific rules are as follows,

1. Users can publish articles on the **platform** and become **authors**.
2. All articles are paid articles, priced by *PressOne Token* with a minimum of 1 PRS.
3. Users can pay for the articles, i.e. become a **reader** of a article.
4. For every new income from an article, 40% will be allocated to each **early reader** on a pro-rata basis as **Early Reader Bonus** , 10% will be a handling fee for the **platform**, and the rest will be revenue for the **author**.
5. **Readers** can also increase the amount they pay for an article by means of a reward in order to increase their share of the bonus.

For example: 

User A published an article X pricing 10 PRS on the platform. 

User B paid 10 PRS for article X and got the right to read the article. 

Therefore, article X earned 10 PRS, because B is the first reader and there is no earlier reader, so there is no early reader bonus; 1 PRS(10%) is used as the platform's handling fee; The remaining 9 PRS are all taken as author revenue and transferred to the account of author A.

User C paid 10 PRS for article x after B. As a result, Article X earns another 10 PRS.

Among them, 4 PRS(40%) will be used as an early reader bonus. At this time, there is only one early reader,  user B, so B monopolizes this 40% reward; The platform also receives 1 PRS(10%) as a handling fee; The remaining 5 PRS is the author's income. 

After C, user D also paid 10 PRS for article X.

Similarly, 4 PRS(40%) will be rewarded as early readers bonus. At this time, there are two early readers, namely B and C, who paid 10 PRS for article X before, so both B and C will be rewarded with ` 4 * 10/(10+10) = 2` PRS respectively. 

The platform also charges 1 PRS(10%) as a handling fee; The remaining 5 PRS is the author's income. 

And so on. 

It is worth reminding that besides the payment for articles, the income from other payment behaviors (such as reward) will also be included in the distribution ratio of early readers' bonus. 

## Experience 

At present, PRSDigg only supports [mixin messenger](https://mixin.one/messenger) login and payment. Please download and install it before experiencing PRSDigg.

Browse [prsdigg.com](https://prsdigg.com/), or search for Bot 7000101549 in [mixin messenger](https://mixin.one/messenger).




