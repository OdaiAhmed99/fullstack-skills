from rest_framework.test import APITestCase


class HealthTests(APITestCase):
    def test_health_answers_ok_without_login(self):
        response = self.client.get("/api/core/health/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["database"], "ok")
