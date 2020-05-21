require 'apple_id_token/version'
require 'jwt'
require 'httparty'
require 'json'

module AppleIdToken
  class PublicKeysError < StandardError; end
  class ValidationError < StandardError; end
  class SignatureError < ValidationError; end
  class InvalidPublicKey < ValidationError; end
  class ExpiredJWTSignature < ValidationError; end
  class JWTAudienceError < ValidationError; end

  class Validator
    APPLE_ISSUER = 'https://appleid.apple.com'
    APPLE_JWKS_URI = 'https://appleid.apple.com/auth/keys'

    HTTP_OK = 200

    JWT_HS256 = 'HS256'

    class << self
      def validate(token:, aud:)
        public_keys = get_public_keys
        if public_keys
          payload = check_against_certs(token, aud, public_keys)

          unless payload
            raise SignatureError, 'Token not verified as issued by Apple'
          end
        else
          raise PublicKeysError, 'Unable to retrieve Apple public keys'
        end
      end

      private

      def get_public_keys
        response = HTTParty.get(APPLE_JWKS_URI)
        return false unless response.code == HTTP_OK

        json_body = JSON.parse(response.body)
        json_body['keys']
      end

      def check_against_certs(token, aud, public_keys)
        payload = nil

        public_keys.each do |public_key|
          # As jwk from jwt library needs Hashes with keys as symbols.
          public_key = public_key.transform_keys(&:to_sym)

          begin
            jwk = JWT::JWK.import(public_key)
            payload = JWT.decode(token, jwk.public_key , !!public_key, {
                algorithm: JWT_HS256,
                iss: APPLE_ISSUER, verify_iss: true,
                aud: aud, verify_aud: true
              }
            )

            return nil unless payload
          rescue JWT::JWKError
            raise InvalidPublicKey, 'Provided public key was invalid'
          rescue JWT::ExpiredSignature
            raise ExpiredJWTSignature, 'Token signature is expired'
          rescue JWT::InvalidIssuerError
            raise SignatureError, 'Token not verified as issued by Apple'
          rescue JWT::InvalidAudError
            raise JWTAudienceError, 'Token audience mismatch'
          rescue JWT::DecodeError
            nil # Try another public key.
          end
        end
      end
    end
  end
end
