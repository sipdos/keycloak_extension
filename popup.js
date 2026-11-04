document.addEventListener('DOMContentLoaded', async () => {
  const countEl = document.getElementById('count');
  const statusEl = document.getElementById('status');
  const clearBtn = document.getElementById('clear');

  async function refresh() {
    const stats = await chrome.runtime.sendMessage({ type: 'STATS' });
    countEl.textContent = stats?.entries ?? 0;
  }

  clearBtn.addEventListener('click', async () => {
    await chrome.runtime.sendMessage({ type: 'CLEAR' });
    statusEl.textContent = '✅ Memoria limpiada';
    setTimeout(() => statusEl.textContent = '', 2000);
    refresh();
  });

  refresh();
});