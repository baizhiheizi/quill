import { post } from '@rails/request.js';

export async function getNounce(account) {
  const res = await post('/nounce', {
    body: {
      public_key: account,
    },
    contentType: 'application/json',
  });

  return await res.json;
}

export async function authorize() {
  if (!window.w3) return;

  const accounts = await w3.eth.getAccounts();
  const account = accounts[0];
  const nounce = await getNounce(account);
  const signature = await w3.eth.personal.sign(JSON.stringify(nounce), account);

  Turbo.visit(
    `/auth/mvm/callback?signature=${signature}&public_key=${account}&provider=${
      w3.provider
    }&return_to=${encodeURIComponent(location.href)}`,
  );
}
