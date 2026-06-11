require('dotenv').config();

const express    = require('express');
const session    = require('express-session');
const path       = require('path');

const authMiddleware    = require('./middleware/auth');
const containersRouter = require('./routes/containers');
const logsRouter       = require('./routes/logs');
const rollbackRouter   = require('./routes/rollback');
const historyRouter    = require('./routes/history');
const authRouter       = require('./routes/auth');

const app  = express();
app.set('trust proxy', 1);
const PORT = process.env.PORT || 4000;

// --- Middlewares globales ---
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// --- Sesión ---
app.use(session({
  secret: process.env.SESSION_SECRET || 'secreto',
  resave: false,
  saveUninitialized: false,
  cookie: { maxAge: 1000 * 60 * 60 * 8, path: '/' } // 8 horas
}));

// --- Archivos estáticos (frontend) ---
// login.html es público, el resto requiere sesión
app.use('/dashboard', express.static(path.join(__dirname, 'public')));


// --- Rutas de autenticación (públicas) ---
app.use('/auth', authRouter);

// --- Rutas protegidas (requieren login) ---
app.use('/api/containers', authMiddleware, containersRouter);
app.use('/api/logs',       authMiddleware, logsRouter);
app.use('/api/rollback',   authMiddleware, rollbackRouter);
app.use('/api/history',    authMiddleware, historyRouter);

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// --- Frontend protegido ---


// --- Health check (público, para Docker y CI/CD) ---

app.listen(PORT, () => {
  console.log(`Dashboard corriendo en http://localhost:${PORT}`);
});
