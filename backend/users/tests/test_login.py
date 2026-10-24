from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase

User = get_user_model()
URL = "/api/auth/login/"


class LoginTests(APITestCase):
    @classmethod
    def setUpTestData(cls):
        cls.user = User.objects.create_user(username="sara", email="sara@example.com", password="pass12345")

    def test_login_with_username(self):
        r = self.client.post(URL, {"login": "sara", "password": "pass12345"})
        self.assertEqual(r.status_code, 200)
        self.assertIn("access", r.data)
        self.assertEqual(r.data["user"]["email"], "sara@example.com")

    def test_login_with_email_any_case(self):
        r = self.client.post(URL, {"login": "Sara@Example.com", "password": "pass12345"})
        self.assertEqual(r.status_code, 200)

    def test_wrong_password_is_400_with_one_message(self):
        r = self.client.post(URL, {"login": "sara", "password": "nope"})
        self.assertEqual(r.status_code, 400)

    def test_unknown_login_gives_same_answer(self):
        r = self.client.post(URL, {"login": "ghost@example.com", "password": "nope"})
        self.assertEqual(r.status_code, 400)

    def test_inactive_user_cannot_log_in(self):
        User.objects.create_user(username="off", email="off@example.com", password="pass12345", is_active=False)
        r = self.client.post(URL, {"login": "off", "password": "pass12345"})
        self.assertEqual(r.status_code, 400)

    def test_me_needs_token(self):
        self.assertEqual(self.client.get("/api/auth/me/").status_code, 401)
        token = self.client.post(URL, {"login": "sara", "password": "pass12345"}).data["access"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
        self.assertEqual(self.client.get("/api/auth/me/").data["username"], "sara")
