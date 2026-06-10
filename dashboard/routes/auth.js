const express = require('express');
const router  = express.Router();

// POST /auth/login
router.post('/login', (req, res) => {
  const { username, password } = req.body;

  const validUser = process.env.DASHBOARD_USER || 'admin';
  const validPass = process.env.DASHBOARD_PASS || 'admin';

  if (username === validUser && password === validPass) {
    req.session.user = username;
    return res.redirect('/dashboard');
  }

  res.redirect('/dashboard/login.html?error=1');
});

// POST /auth/logout
router.post('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/dashboard/login.html');
});

module.exports = router;
