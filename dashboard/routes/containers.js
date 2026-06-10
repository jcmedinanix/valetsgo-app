const express   = require('express');
const Docker    = require('dockerode');
const { logAction } = require('../middleware/logger');

const router = express.Router();
const docker = new Docker({ socketPath: '/var/run/docker.sock' });

// GET /api/containers — lista todos los contenedores
router.get('/', async (req, res) => {
  try {
    const containers = await docker.listContainers({ all: true });
    const result = containers.map(c => ({
      id:      c.Id.substring(0, 12),
      name:    c.Names[0].replace('/', ''),
      image:   c.Image,
      status:  c.Status,
      state:   c.State,
      ports:   c.Ports
    }));
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/containers/:id/restart — reinicia un contenedor
router.post('/:id/restart', async (req, res) => {
  try {
    const container = docker.getContainer(req.params.id);
    await container.restart();
    logAction(req.session.user, 'RESTART', req.params.id, 'success');
    res.json({ ok: true, message: 'Contenedor reiniciado' });
  } catch (err) {
    logAction(req.session.user, 'RESTART', req.params.id, 'error: ' + err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
