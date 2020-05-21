require 'spec_helper'
require 'fakeweb'
require 'openssl'

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
      let(:binary) { 2 }
      let(:jwk) { JWT::JWK.new(OpenSSL::PKey::RSA.new(2048)) }
      let(:jwk_n) { Base64.urlsafe_encode64(jwk.keypair.public_key.n.to_s(binary), padding: false) }
      let(:jwk_e) { Base64.urlsafe_encode64(jwk.keypair.public_key.e.to_s(binary), padding: false) }
      let(:headers) { { kid: jwk.kid } }

      let(:successful_body_response) {
        {
          keys: [
            {
              kty: "RSA",
              kid: jwk.kid,
              use: "sig",
              alg: "RS256",
              n: jwk_n,
              e: jwk_e
            },
            {
              kty: "RSA",
              kid: jwk.kid,
              use: "sig",
              alg: "RS256",
              n: jwk_n,
              e: jwk_e
            }
          ]
        }
      }

      before do
        FakeWeb::register_uri(:get,
          AppleIdToken::Validator::APPLE_JWKS_URI,
          status: ['200', 'OK'],
          body: JSON.dump(successful_body_response)
        )
      end

      let(:iss) { AppleIdToken::Validator::APPLE_ISSUER }
      let(:aud) { 'fake_client.apple.com' }
      let(:exp) { Time.now + 5 }

      let(:payload) {{
        exp: exp.to_i,
        iss: iss,
        aud: aud,
        sub: 'fake_user_id',
        email: 'thisisafakeemail@apple.com',
        email_verified: true
      }}

      context 'and valid token info' do
        let(:token) { JWT.encode(payload, jwk.keypair, 'RS256', headers) }

        it 'returns payload with provided info' do
          validated_payload = validator.validate(token: token, aud: aud)
          validated_payload_sym = validated_payload.transform_keys(&:to_sym)
          expect(validated_payload_sym).to eq payload
        end
      end

      context 'and invalid token info' do
        context 'when expired signature' do
          before do
            payload[:exp] = (Time.now - 5).to_i
          end

          let(:token) { JWT.encode(payload, jwk.keypair, 'RS256', headers) }

          it 'raises JWTExpiredSignatureError' do
            expect {
              validator.validate(token: token, aud: aud)
            }.to raise_error(AppleIdToken::JWTExpiredSignatureError)
          end
        end

        context 'when invalid issuer' do
          before do
            payload[:iss] = 'fake_issuer'
          end

          let(:token) { JWT.encode(payload, jwk.keypair, 'RS256', headers) }

          it 'raises JWTSignatureError' do
            expect {
              validator.validate(token: token, aud: aud)
            }.to raise_error(AppleIdToken::JWTSignatureError)
          end
        end

        context 'when invalid audience' do
          let(:token) { JWT.encode(payload, jwk.keypair, 'RS256', headers) }

          it 'raises JWTAudienceError' do
            expect {
              validator.validate(token: token, aud: fake_aud)
            }.to raise_error(AppleIdToken::JWTAudienceError)
          end
        end
      end

      context 'and no payload found' do
        before do
          allow(validator).to receive(:check_against_certs).and_return(nil)
        end

        it 'raises JWTSignatureError' do
          expect {
            validator.validate(token: fake_token, aud: fake_aud)
          }.to raise_error(AppleIdToken::JWTSignatureError)
        end
      end
    end

    context 'when no valid public keys' do
      let(:successful_body_response) {
        {
          keys: [
            {
              kid: "86D88Kf",
              use: "sig",
              alg: "RS256",
              n: "iGaLqP6y-SJCCBq5Hv6pGDbG_SQ11MNjH7rWHcCFYz4hGwHC4lcSurTlV8u3avoVNM8jXevG1Iu1SY11qInqUvjJur--hghr1b56OPJu6H1iKulSxGjEIyDP6c5BdE1uwprYyr4IO9th8fOwCPygjLFrh44XEGbDIFeImwvBAGOhmMB2AD1n1KviyNsH0bEB7phQtiLk-ILjv1bORSRl8AK677-1T8isGfHKXGZ_ZGtStDe7Lu0Ihp8zoUt59kx2o9uWpROkzF56ypresiIl4WprClRCjz8x6cPZXU2qNWhu71TQvUFwvIvbkE1oYaJMb0jcOTmBRZA2QuYw-zHLwQ",
              e: "AQAB"
            },
            {
              kid: "eXaunmL",
              use: "sig",
              alg: "RS256",
              n: "4dGQ7bQK8LgILOdLsYzfZjkEAoQeVC_aqyc8GC6RX7dq_KvRAQAWPvkam8VQv4GK5T4ogklEKEvj5ISBamdDNq1n52TpxQwI2EqxSk7I9fKPKhRt4F8-2yETlYvye-2s6NeWJim0KBtOVrk0gWvEDgd6WOqJl_yt5WBISvILNyVg1qAAM8JeX6dRPosahRVDjA52G2X-Tip84wqwyRpUlq2ybzcLh3zyhCitBOebiRWDQfG26EH9lTlJhll-p_Dg8vAXxJLIJ4SNLcqgFeZe4OfHLgdzMvxXZJnPp_VgmkcpUdRotazKZumj6dBPcXI_XID4Z4Z3OM1KrZPJNdUhxw",
              e: "AQAB"
            }
          ]
        }
      }

      before do
        FakeWeb::register_uri(:get,
          AppleIdToken::Validator::APPLE_JWKS_URI,
          status: ['200', 'OK'],
          body: JSON.dump(successful_body_response)
        )
      end

      it 'raises error InvalidPublicKeyError' do
        expect {
          validator.validate(token: fake_token, aud: fake_aud)
        }.to raise_error(AppleIdToken::InvalidPublicKeyError)
      end
    end
  end
end
