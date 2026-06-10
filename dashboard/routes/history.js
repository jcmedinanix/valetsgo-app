const express = require('express');
const fs      = require('fs');
const path    = require('path');

const router      = express.Router();
const historyFile = path.join(__dirname, '../data/history.json');

// GET /api/history
router.get('/', (req, res) => {
  try {
    if (!fs.existsSync(historyFile)) {
      return res.json([]);
    }
    const history = JSON.parse(fs.readFileSync(historyFile, 'utf8'));
    res.json(history);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
