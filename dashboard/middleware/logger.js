const fs   = require('fs');
const path = require('path');

const historyFile = path.join(__dirname, '../data/history.json');

// Se asegura que el archivo existe al arrancar
if (!fs.existsSync(historyFile)) {
  fs.writeFileSync(historyFile, JSON.stringify([], null, 2));
}

// Guarda una operación en el historial
const logAction = (user, action, detail, result) => {
  try {
    const history = JSON.parse(fs.readFileSync(historyFile, 'utf8'));
    history.unshift({
      timestamp: new Date().toISOString(),
      user:      user || 'sistema',
      action,
      detail,
      result
    });
    // Guarda solo los últimos 100 registros
    fs.writeFileSync(historyFile, JSON.stringify(history.slice(0, 100), null, 2));
  } catch (err) {
    console.error('Error al guardar historial:', err.message);
  }
};

module.exports = { logAction };
