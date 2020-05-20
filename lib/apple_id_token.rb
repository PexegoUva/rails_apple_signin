require 'apple_id_token/version'
require 'jwt'
require 'httparty'
require 'json'

module AppleIdToken
  class PublicKeysError < StandardError; end
  class ValidationError < StandardError; end
  class SignatureError < ValidationError; end

  class Validator
    APPLE_ISSUER = 'https://appleid.apple.com'
    APPLE_JWKS_URI = 'https://appleid.apple.com/auth/keys'

    class << self
      def validate(token:, aud:)
        if get_public_keys
          payload = check_against_certs(token, aud)

          unless payload
            raise SignatureError, 'Token not verified as issued by Apple'
          end
        else
          raise PublicKeysError, 'Unable to retrieve Apple public keys'
        end
      end

      private

      def get_public_keys
        # TODO -> Implement
      end

      def check_against_certs(token, aud)
        # TODO -> Implement
      end
    end
  end
end
