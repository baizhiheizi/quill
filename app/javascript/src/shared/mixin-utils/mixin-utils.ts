class MixinUtils {
  public environment() {
    if (
      (window as any).webkit &&
      (window as any).webkit.messageHandlers &&
      (window as any).webkit.messageHandlers.MixinContext
    ) {
      return 'iOS';
    }
    if (
      (window as any).MixinContext &&
      (window as any).MixinContext.getContext
    ) {
      return 'Android';
    }
    return undefined;
  }

  public conversationId() {
    let ctx: any;
    switch (this.environment()) {
      case 'iOS':
        ctx = prompt('MixinContext.getContext()');
        return JSON.parse(ctx).conversation_id;
      case 'Android':
        ctx = (window as any).MixinContext.getContext();
        return JSON.parse(ctx).conversation_id;
      default:
        return undefined;
    }
  }

  public appVersion() {
    let ctx: any;
    switch (this.environment()) {
      case 'iOS':
        ctx = prompt('MixinContext.getContext()');
        return JSON.parse(ctx).app_version;
      case 'Android':
        ctx = (window as any).MixinContext.getContext();
        return JSON.parse(ctx).app_version;
      default:
        return undefined;
    }
  }

  public immersive() {
    let ctx: any;
    switch (this.environment()) {
      case 'iOS':
        ctx = prompt('MixinContext.getContext()');
        return JSON.parse(ctx).immersive;
      case 'Android':
        ctx = (window as any).MixinContext.getContext();
        return JSON.parse(ctx).immersive;
      default:
        return undefined;
    }
  }
}

export const mixinUtils = new MixinUtils();
