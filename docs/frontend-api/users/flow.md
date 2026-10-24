# Users - login flow

Field detail is in the API doc ("auth"). This is the call sequence.

1. **Login screen** - one box for username or email, one for password. `POST /api/auth/login/` - log in and get tokens + the user.
2. **App load** - `GET /api/auth/me/` - who is logged in.
3. **Token expiry** - `POST /api/auth/refresh/` - done by the client on a 401; the refresh token rotates.

**The login flow ends here.**
