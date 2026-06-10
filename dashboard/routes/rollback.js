const express = require('express');
const Docker  = require('dockerode');
const https   = require('https');
const { logAction } = require('../middleware/logger');

const router = express.Router();
const docker = new Docker({ socketPath: '/var/run/docker.sock' });
const IMAGE  = process.env.DOCKER_IMAGE || 'jcmedinanix/valetsgo-app';

// Consulta los últimos tags de Docker Hub
const getDockerHubTags = () => {
  return new Promise((resolve, reject) => {
    const url = `https://hub.docker.com/v2/repositories/${IMAGE}/tags?page_size=10`;
    https.get(url, { headers: { 'User-Agent': 'valetsgo-dashboard' } }, (resp) => {
      let data = '';
      resp.on('data', chunk => data += chunk);
      resp.on('end', () => {
        try {
          const json = JSON.parse(data);
          const tags = (json.results || []).map(t => ({
            tag:     t.name,
            pushed:  t.tag_last_pushed,
            size:    t.full_size
          }));
          resolve(tags);
        } catch (e) { reject(e); }
      });
    }).on('error', reject);
  });
};

// GET /api/rollback/versions
router.get('/versions', async (req, res) => {
  try {
    const tags = await getDockerHubTags();
    res.json(tags);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/rollback — ejecuta el rollback
router.post('/', async (req, res) => {
  const { tag, containerName } = req.body;
  if (!tag || !containerName) {
    return res.status(400).json({ error: 'Faltan parámetros: tag y containerName' });
  }

  const fullImage = `${IMAGE}:${tag}`;
  logAction(req.session.user, 'ROLLBACK_START', fullImage, 'iniciado');

  try {
    // 1. Descargar la imagen del tag elegido
    await new Promise((resolve, reject) => {
      docker.pull(fullImage, (err, stream) => {
        if (err) return reject(err);
        docker.modem.followProgress(stream, (err) => err ? reject(err) : resolve());
      });
    });

    // 2. Obtener el contenedor actual
    const container = docker.getContainer(containerName);
    const info      = await container.inspect();

    // 3. Detener y eliminar el contenedor actual
    await container.stop();
    await container.remove();

    // 4. Crear y arrancar el nuevo contenedor con la imagen anterior
    const newContainer = await docker.createContainer({
      name:         containerName,
      Image:        fullImage,
      ExposedPorts: info.Config.ExposedPorts,
      HostConfig:   info.HostConfig
    });
    await newContainer.start();

    logAction(req.session.user, 'ROLLBACK_OK', fullImage, 'success');
    res.json({ ok: true, message: `Rollback a ${fullImage} completado` });

  } catch (err) {
    logAction(req.session.user, 'ROLLBACK_ERROR', fullImage, 'error: ' + err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
