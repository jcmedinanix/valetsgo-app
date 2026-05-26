const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.APP_VERSION || '1.3.0';

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>ValetsGo S.A.C.</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: 'Segoe UI', sans-serif;
          background: linear-gradient(135deg, #1a1a2e, #16213e, #0f3460);
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          color: white;
        }
        .container {
          text-align: center;
          padding: 40px;
          background: rgba(255,255,255,0.05);
          border-radius: 20px;
          border: 1px solid rgba(255,255,255,0.1);
          backdrop-filter: blur(10px);
          max-width: 600px;
          width: 90%;
        }
        .logo { font-size: 3rem; font-weight: 900; color: #e94560; letter-spacing: 2px; }
        .subtitle { font-size: 1rem; color: #a0a0b0; margin: 8px 0 30px; }
        .badge {
          display: inline-block;
          background: #e94560;
          color: white;
          padding: 6px 16px;
          border-radius: 20px;
          font-size: 0.85rem;
          margin-bottom: 30px;
        }
        .info-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 15px;
          margin-top: 20px;
        }
        .info-card {
          background: rgba(255,255,255,0.05);
          border-radius: 10px;
          padding: 15px;
          border: 1px solid rgba(255,255,255,0.08);
        }
        .info-label { font-size: 0.75rem; color: #a0a0b0; text-transform: uppercase; }
        .info-value { font-size: 1.1rem; font-weight: 600; margin-top: 4px; color: #e94560; }
        .status-dot {
          display: inline-block;
          width: 10px; height: 10px;
          background: #00ff88;
          border-radius: 50%;
          margin-right: 6px;
          animation: pulse 2s infinite;
        }
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.4; }
        }
        .footer { margin-top: 30px; font-size: 0.75rem; color: #606070; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="logo">ValetsGo</div>
        <div class="subtitle">S.A.C. — Chiclayo, Perú</div>
        <div class="badge">🚀 Arquitectura DevOps — Tesis USAT 2026</div>
        <div class="info-grid">
          <div class="info-card">
            <div class="info-label">Versión</div>
            <div class="info-value">v${VERSION}</div>
          </div>
          <div class="info-card">
            <div class="info-label">Estado</div>
            <div class="info-value"><span class="status-dot"></span>Activo</div>
          </div>
          <div class="info-card">
            <div class="info-label">Entorno</div>
            <div class="info-value">Producción</div>
          </div>
          <div class="info-card">
            <div class="info-label">Infraestructura</div>
            <div class="info-value">OCI + Docker</div>
          </div>
        </div>
        <div class="footer">
          Implementación DevOps — Juan Carlos Medina Ruiz — USAT 2026
        </div>
      </div>
    </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    version: VERSION,
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    service: 'valetsgo-app'
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`ValetsGo App v${VERSION} corriendo en puerto ${PORT}`);
});
