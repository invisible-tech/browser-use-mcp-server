import os
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from dotenv import load_dotenv

load_dotenv()

import pyotp

from browser_use import ActionResult, Controller


controller = Controller()


@controller.registry.action('Get 2FA code from OTP secret key')
async def get_otp_2fa(otp_secret_key: str | None = None) -> ActionResult:
	"""
	Custom action to retrieve 2FA/MFA code from OTP secret key using pyotp.
	
	Args:
		otp_secret_key: The OTP secret key to generate the code for
		
	Returns:
		ActionResult containing the generated OTP code
		
	Raises:
		ValueError: If otp_secret_key is not provided or is empty
	"""
	if not otp_secret_key:
		raise ValueError('otp_secret_key parameter is required')
	try:
		totp = pyotp.TOTP(otp_secret_key)
		code = totp.now()
		return ActionResult(extracted_content=code)
	except Exception as e:
		print(f"Error generating OTP code")
		raise ValueError(f"Error generating OTP code")