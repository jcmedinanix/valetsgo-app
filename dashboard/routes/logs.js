const express = require('express');
const Docker  = require('dockerode');

const router = express.Router();
const docker = new Docker({ socketPath: '/var/run/docker.sock' });

// GET /api/logs/:id — últimas 100 líneas de log
router.get('/:id', async (req, res) => {
  try {
    const container = docker.getContainer(req.params.id);
    const logs = await container.logs({
      stdout: true,
      stderr: true,
      tail:   100,
      timestamps: true
    });
    // Docker devuelve un Buffer con cabeceras binarias — las limpiamos
    const clean = logs.toString('utf8')
      .split('\n')
      .map(line => line.substring(8)) // quita los 8 bytes de cabecera Docker
      .join('\n');
    res.json({ logs: clean });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
