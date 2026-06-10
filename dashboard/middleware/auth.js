// Verifica que el usuario tenga sesión activa
// Si no, lo redirige al login
module.exports = (req, res, next) => {
  if (req.session && req.session.user) {
    return next(); // tiene sesión, continúa
  }
  // Si es una llamada a la API, devuelve JSON
  if (req.path.startsWith('/api/')) {
    return res.status(401).json({ error: 'No autorizado' });
  }
  // Si es una página, redirige al login
  res.redirect('/dashboard/login.html');
};
