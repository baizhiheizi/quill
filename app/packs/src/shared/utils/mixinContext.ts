const getMixinContext: () => {
  appVersion?: string;
  immersive?: boolean;
  appearance?: 'dark' | 'light';
  currency?:
    | 'USD'
    | 'CNY'
    | 'JPY'
    | 'EUR'
    | 'KRW'
    | 'HKD'
    | 'GBP'
    | 'AUD'
    | 'SGD'
    | 'MYR';
  locale: string;
  platform: 'iOS' | 'Android' | 'Desktop';
  conversationId: string;
} = () => {
  let ctx: any = {};
  if (
    (window as any).webkit &&
    (window as any).webkit.messageHandlers &&
    (window as any).webkit.messageHandlers.MixinContext
  ) {
    ctx = JSON.parse(prompt('MixinContext.getContext()'));
    ctx.platform = ctx.platform || 'iOS';
  } else if (
    (window as any).MixinContext &&
    typeof (window as any).MixinContext.getContext === 'function'
  ) {
    ctx = JSON.parse((window as any).MixinContext.getContext());
    ctx.platform = ctx.platform || 'Android';
  }
  ctx.appVersion = ctx.app_version;
  ctx.conversationId = ctx.conversation_id;
  return ctx;
};

export const mixinContext = getMixinContext();
