document.addEventListener('DOMContentLoaded', () => {
  loadContainers();
  loadVersions();
  loadHistory();
});

// --- CONTENEDORES ---
async function loadContainers() {
  const tbody = document.getElementById('containers-tbody');
  tbody.innerHTML = '<tr><td colspan="4" class="empty-msg"><span class="spinner"></span>Cargando...</td></tr>';
  try {
    const res  = await fetch('/api/containers');
    const data = await res.json();
    if (!data.length) {
      tbody.innerHTML = '<tr><td colspan="4" class="empty-msg">No hay contenedores</td></tr>';
      return;
    }
    const logSelect        = document.getElementById('log-select');
    const rollbackContainer = document.getElementById('rollback-container');
    logSelect.innerHTML        = '<option value="">Selecciona un contenedor</option>';
    rollbackContainer.innerHTML = '<option value="">Selecciona contenedor</option>';
    tbody.innerHTML = data.map(c => {
      const badge = c.state === 'running'
        ? `<span class="badge badge-green">● running</span>`
        : `<span class="badge badge-red">● ${c.state}</span>`;
      logSelect.innerHTML        += `<option value="${c.id}">${c.name}</option>`;
      if (c.name === "valetsgo-app") rollbackContainer.innerHTML += `<option value="${c.name}">${c.name}</option>`;
      return `<tr>
        <td><strong>${c.name}</strong></td>
        <td style="font-size:0.8rem;color:#6b7280">${c.image}</td>
        <td>${badge}</td>
        <td>
          <button class="btn-secondary" onclick="restartContainer('${c.id}','${c.name}')">
            ↻ Reiniciar
          </button>
        </td>
      </tr>`;
    }).join('');
  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="4" class="empty-msg">Error: ${err.message}</td></tr>`;
  }
}

async function restartContainer(id, name) {
  if (!confirm(`¿Reiniciar el contenedor "${name}"?`)) return;
  try {
    const res  = await fetch(`/api/containers/${id}/restart`, { method: 'POST' });
    const data = await res.json();
    alert(data.message || data.error);
    loadContainers();
    loadHistory();
  } catch (err) {
    alert('Error: ' + err.message);
  }
}

// --- LOGS ---
async function loadLogs() {
  const id  = document.getElementById('log-select').value;
  const box = document.getElementById('log-box');
  if (!id) { box.textContent = 'Selecciona un contenedor para ver sus logs...'; return; }
  box.textContent = 'Cargando logs...';
  try {
    const res  = await fetch(`/api/logs/${id}`);
    const data = await res.json();
    box.textContent = data.logs || 'Sin logs disponibles';
    box.scrollTop   = box.scrollHeight;
  } catch (err) {
    box.textContent = 'Error al cargar logs: ' + err.message;
  }
}

// --- ROLLBACK ---
async function loadVersions() {
  const sel = document.getElementById('rollback-tag');
  try {
    const res  = await fetch('/api/rollback/versions');
    const tags = await res.json();
    if (!tags.length) {
      sel.innerHTML = '<option value="">No hay versiones disponibles</option>';
      return;
    }
    sel.innerHTML = tags.map(t =>
      `<option value="${t.tag}">${t.tag} — ${new Date(t.pushed).toLocaleDateString('es-PE')}</option>`
    ).join('');
  } catch (err) {
    sel.innerHTML = '<option value="">Error al cargar versiones</option>';
  }
}

async function doRollback() {
  const tag           = document.getElementById('rollback-tag').value;
  const containerName = document.getElementById('rollback-container').value;
  const msg           = document.getElementById('rollback-msg');
  if (!tag || !containerName) {
    msg.innerHTML = '<span style="color:#dc2626">Selecciona un contenedor y una versión.</span>';
    return;
  }
  if (!confirm(`¿Ejecutar rollback de "${containerName}" a la versión "${tag}"?\nEsto detendrá y recreará el contenedor.`)) return;
  msg.innerHTML = '<span class="spinner"></span>Ejecutando rollback...';
  try {
    const res  = await fetch('/api/rollback', {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body:    JSON.stringify({ tag, containerName })
    });
    const data = await res.json();
    if (data.ok) {
      msg.innerHTML = `<span style="color:#166534">✓ ${data.message}</span>`;
      loadContainers();
      loadHistory();
    } else {
      msg.innerHTML = `<span style="color:#dc2626">Error: ${data.error}</span>`;
    }
  } catch (err) {
    msg.innerHTML = `<span style="color:#dc2626">Error: ${err.message}</span>`;
  }
}

// --- HISTORIAL ---
async function loadHistory() {
  const list = document.getElementById('history-list');
  try {
    const res  = await fetch('/api/history');
    const data = await res.json();
    if (!data.length) {
      list.innerHTML = '<li class="empty-msg">No hay operaciones registradas aún</li>';
      return;
    }
    list.innerHTML = data.map(h => {
      const isOk  = h.result === 'success' || h.result === 'iniciado';
      const badge = isOk
        ? `<span class="badge badge-green">${h.result}</span>`
        : `<span class="badge badge-red">${h.result}</span>`;
      return `<li class="history-item">
        <span class="history-time">${new Date(h.timestamp).toLocaleString('es-PE')}</span>
        <div>
          <div class="history-action"><strong>${h.action}</strong> — ${h.detail} ${badge}</div>
          <div class="history-detail">Usuario: ${h.user}</div>
        </div>
      </li>`;
    }).join('');
  } catch (err) {
    list.innerHTML = `<li class="empty-msg">Error: ${err.message}</li>`;
  }
}
