require 'spec_helper'
require 'fakeweb'

RSpec.describe AppleIdToken::Validator do
  describe '.validate' do
    subject(:validator) { AppleIdToken::Validator }

    let(:fake_token) { 'definitely_a_fake_token' }
    let(:fake_aud) { 'not_a_real_user_id' }

    context 'when unable to retrieve Apple public keys' do
      before do
        FakeWeb::register_uri(:get,
          AppleIdToken::Validator::APPLE_JWKS_URI,
          status: ['404', 'Not found'],
          body: 'It seems that our little goblins were not able to give you the info you wanted. Try another one.'
        )
      end

      it 'raises PublicKeysError' do
        expect {
          validator.validate(token: fake_token, aud: fake_aud)
        }.to raise_error(AppleIdToken::PublicKeysError)
      end
    end

    context 'when valid public keys' do
      before do
        FakeWeb::register_uri(:get,
          AppleIdToken::Validator::APPLE_JWKS_URI,
          status: ['200', 'OK'],
          body: {
            "keys": [
              {
                "kty": "RSA",
                "kid": "86D88Kf",
                "use": "sig",
                "alg": "RS256",
                "n": "iGaLqP6y-SJCCBq5Hv6pGDbG_SQ11MNjH7rWHcCFYz4hGwHC4lcSurTlV8u3avoVNM8jXevG1Iu1SY11qInqUvjJur--hghr1b56OPJu6H1iKulSxGjEIyDP6c5BdE1uwprYyr4IO9th8fOwCPygjLFrh44XEGbDIFeImwvBAGOhmMB2AD1n1KviyNsH0bEB7phQtiLk-ILjv1bORSRl8AK677-1T8isGfHKXGZ_ZGtStDe7Lu0Ihp8zoUt59kx2o9uWpROkzF56ypresiIl4WprClRCjz8x6cPZXU2qNWhu71TQvUFwvIvbkE1oYaJMb0jcOTmBRZA2QuYw-zHLwQ",
                "e": "AQAB"
              },
              {
                "kty": "RSA",
                "kid": "eXaunmL",
                "use": "sig",
                "alg": "RS256",
                "n": "4dGQ7bQK8LgILOdLsYzfZjkEAoQeVC_aqyc8GC6RX7dq_KvRAQAWPvkam8VQv4GK5T4ogklEKEvj5ISBamdDNq1n52TpxQwI2EqxSk7I9fKPKhRt4F8-2yETlYvye-2s6NeWJim0KBtOVrk0gWvEDgd6WOqJl_yt5WBISvILNyVg1qAAM8JeX6dRPosahRVDjA52G2X-Tip84wqwyRpUlq2ybzcLh3zyhCitBOebiRWDQfG26EH9lTlJhll-p_Dg8vAXxJLIJ4SNLcqgFeZe4OfHLgdzMvxXZJnPp_VgmkcpUdRotazKZumj6dBPcXI_XID4Z4Z3OM1KrZPJNdUhxw",
                "e": "AQAB"
              }
            ]
          }
        )
      end

      it 'validates token' do
        # TODO -> Implement
      end

      it 'returns payload with provided info' do
        # TODO -> Implement
      end

      context 'and no payload found' do
        before do
          allow(validator).to receive(:get_public_keys).and_return(true)
          allow(validator).to receive(:check_against_certs).with(fake_token, fake_aud).and_return(nil)
        end

        it 'raises SignatureError' do
          expect {
            validator.validate(token: fake_token, aud: fake_aud)
          }.to raise_error(AppleIdToken::SignatureError)
        end
      end
    end
  end
end
