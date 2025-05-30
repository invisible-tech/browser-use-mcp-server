import os
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from dotenv import load_dotenv

load_dotenv()

import pyotp

from browser_use import ActionResult, Controller


controller = Controller()


@controller.registry.action('Get 2FA code from when OTP is required')
async def get_otp_2fa() -> ActionResult:
	"""
	Custom action to retrieve 2FA/MFA code from OTP secret key using pyotp.
	The OTP secret key should be set in the environment variable OTP_SECRET_KEY.
	"""
	secret_key = os.environ.get('OTP_SECRET_KEY', None)
	if not secret_key:
		raise ValueError('OTP_SECRET_KEY environment variable is not set')

	totp = pyotp.TOTP(secret_key)
	code = totp.now()
	return ActionResult(extracted_content=code)