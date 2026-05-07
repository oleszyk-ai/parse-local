// ── State ─────────────────────────────────────────────────────

let currentMode = 'url';
let lastResult = null;

// ── Mode Switching ────────────────────────────────────────────

function switchMode(mode) {
    currentMode = mode;

    document.querySelectorAll('.mode-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.mode === mode);
    });

    document.getElementById('url-input-section').classList.toggle('hidden', mode !== 'url');
    document.getElementById('html-input-section').classList.toggle('hidden', mode !== 'html');
}

// ── Scraping ──────────────────────────────────────────────────

async function runScrape() {
    const btn = document.getElementById('scrape-btn');
    const btnText = btn.querySelector('.btn-text');
    const btnLoading = btn.querySelector('.btn-loading');
    const resultsSection = document.getElementById('results-section');
    const errorSection = document.getElementById('error-section');

    // Get inputs
    const prompt = document.getElementById('prompt').value.trim();
    let payload = {};

    if (currentMode === 'url') {
        const url = document.getElementById('url').value.trim();
        if (!url) {
            showError('Please enter a URL');
            return;
        }
        payload = { url, prompt: prompt || undefined };
    } else {
        const html = document.getElementById('html').value.trim();
        if (!html) {
            showError('Please paste some HTML content');
            return;
        }
        payload = { html, prompt: prompt || undefined };
    }

    // Set loading state
    btn.disabled = true;
    btnText.classList.add('hidden');
    btnLoading.classList.remove('hidden');
    resultsSection.classList.add('hidden');
    errorSection.classList.add('hidden');

    try {
        const endpoint = currentMode === 'url' ? '/api/scrape/url' : '/api/scrape/html';
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
        });

        const data = await response.json();

        if (data.success) {
            lastResult = data.data;
            document.getElementById('results-output').querySelector('code').textContent =
                JSON.stringify(data.data, null, 2);
            document.getElementById('elapsed-time').textContent =
                `⏱ ${data.elapsed_seconds}s`;
            resultsSection.classList.remove('hidden');
            errorSection.classList.add('hidden');
        } else {
            showError(data.error || 'Unknown error occurred');
        }
    } catch (err) {
        showError(`Network error: ${err.message}`);
    } finally {
        btn.disabled = false;
        btnText.classList.remove('hidden');
        btnLoading.classList.add('hidden');
    }
}   

// ── Helpers ───────────────────────────────────────────────────

function showError(message) {
    const errorSection = document.getElementById('error-section');
    const resultsSection = document.getElementById('results-section');

    document.getElementById('error-message').textContent = message;
    errorSection.classList.remove('hidden');
    resultsSection.classList.add('hidden');
}

function copyResults() {
    if (lastResult) {
        const text = JSON.stringify(lastResult, null, 2);
        navigator.clipboard.writeText(text).then(() => {
            const btn = document.querySelector('.copy-btn');
            const originalText = btn.textContent;
            btn.textContent = '✅ Copied!';
            setTimeout(() => { btn.textContent = originalText; }, 1500);
        });
    }
}

// ── Keyboard shortcut ─────────────────────────────────────────

document.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
        runScrape();
    }
});
