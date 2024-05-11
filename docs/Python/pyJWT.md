[PyJWT](https://pyjwt.readthedocs.io/en/latest/)

## Validate and return user with AWS cognito access token

```py
import json

from typing import Optional

import jwt
import requests

from jwt.algorithms import RSAAlgorithm

from path.to.user_model import User
from path.to.config import config


class UserAuthService:
    def get_current_user(self, access_token: str = None) -> Optional[User]:
        valid_token, current_user = self.validate_and_return_credentials(access_token)
        return current_user if (valid_token and current_user) else None

    def get_public_access_keys(self) -> str:
        auth = config.auth
        url = f"https://cognito-idp.{auth.region}.amazonaws.com/{auth.identity_pool_id}/.well-known/jwks.json"
        response = requests.get(url)
        return response.text

    def find_public_key(self, kid: str) -> tuple[bool, Optional[dict]]:
        public_keys = self.get_public_access_keys()
        public_keys = json.loads(public_keys)
        public_keys = {key["kid"]: key for key in public_keys["keys"]}
        matched_key = public_keys.get(kid)
        return bool(matched_key), matched_key

    def decode_access_token(self, public: dict, access_token: str, alg: str) -> tuple[bool, dict]:
        try:
            public_key = RSAAlgorithm.from_jwk(json.dumps(public))
            payload = jwt.decode(
                access_token,
                public_key,
                algorithms=[alg],
                verify=True,
                options={
                    "verify_exp": True,
                    "verify_nbf": True,
                    "verify_iat": False, # True
                    "verify_aud": False, # True
                    "verify_iss": True,
                },
                audience=config.auth.identity_pool_web_client,
                issuer=f"https://cognito-idp.{config.auth.region}.amazonaws.com/{config.auth.identity_pool_id}",
            )
        except jwt.exceptions.DecodeError as exc:
            return False, {}

        # This should be check if token_use is ID token and "verify_aud" in jwt decode
        if payload["token_use"] != "access":
            return False, {}

        if payload["client_id"] != config.auth.identity_pool_web_client:
            return False, {}

        return True, payload

    def validate_and_return_credentials(self, access_token: str) -> tuple[bool, Optional[User]]:
        valid_token, current_user = False, None

        try:
            headers = jwt.get_unverified_header(access_token)
            valid_pub_key, user_public_key = self.find_public_key(headers.get("kid"))
            if not user_public_key:
                return False, None

            valid_signature, payload = self.decode_access_token(user_public_key, access_token, headers.get("alg"))
            if valid_pub_key and valid_signature:
                valid_token = True
                user_sub_id = payload.get("sub")
                current_user = User.find_by(guid=user_sub_id) if user_sub_id else None
        except Exception as exc:
						return False, None

        return valid_token, current_user

```
