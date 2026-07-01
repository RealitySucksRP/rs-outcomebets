const app = document.getElementById('app');
const outcomesEl = document.getElementById('outcomes');
const closeBtn = document.getElementById('close');
const placeBtn = document.getElementById('place');
const amountEl = document.getElementById('amount');
const selectedEl = document.getElementById('selected');
const stateEl = document.getElementById('state');
const roundEl = document.getElementById('round');
const promptEl = document.getElementById('prompt');
const timerEl = document.getElementById('timer');
const hypeEl = document.getElementById('hype');
const leaveEl = document.getElementById('leave');

let currentGame = null;
let selected = null;

// server-anchored countdown: timeLeft is captured on each sync,
// then ticked locally so we do not depend on client/server clock parity
let timerSeconds = 0;
let timerAnchorMs = 0;

function nui(name, data = {}) {
    return fetch('https://' + GetParentResourceName() + '/' + name, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
}

function showApp(g) {
    currentGame = g;
    app.classList.remove('hidden');
    render(g);
}

function hideApp() {
    app.classList.add('hidden');
    currentGame = null;
    selected = null;
}

function setTimerFromSync(secs) {
    if (typeof secs === 'number' && secs >= 0) {
        timerSeconds = secs;
        timerAnchorMs = Date.now();
    } else {
        timerSeconds = 0;
        timerAnchorMs = 0;
    }
}

function tickTimer() {
    if (!timerAnchorMs) {
        timerEl.textContent = '--';
        return;
    }
    const elapsed = Math.floor((Date.now() - timerAnchorMs) / 1000);
    const remaining = Math.max(0, timerSeconds - elapsed);
    timerEl.textContent = remaining;
}
setInterval(tickTimer, 250);

function stateLabel(s) {
    if (!s) return 'CAGE COLD';
    return s.replaceAll('_', ' ');
}

function render(g) {
    if (!g) return;
    stateEl.textContent = stateLabel(g.state);
    roundEl.textContent = 'Round ' + (g.round || '-') + ' / ' + (g.roundsPerShow || '-');
    promptEl.textContent = g.prompt || 'Walk up to the bank and place your bet.';
    outcomesEl.innerHTML = '';
    (g.outcomes || []).forEach(function (o) {
        const div = document.createElement('div');
        div.className = 'outcome' + (selected === o.id ? ' selected' : '');
        const pool = (g.pool && g.pool[o.id]) || 0;
        const npcPool = Number(o.npcPool || 0);
        let extra = '';
        if (npcPool > 0) extra += '<div class="odds">NPC BANK: $' + npcPool + '</div>';
        if (o.poolShare) extra += '<div class="odds">POOL SHARE: ' + o.poolShare + '%</div>';
        if (o.potential) extra += '<div class="odds">EST. $' + o.potential + ' on default bet</div>';
        div.innerHTML = '<h2>' + (o.label || o.id) + '</h2><div class="pool">CASH POOL: $' + pool + '</div>' + extra;
        div.onclick = function () {
            selected = o.id;
            selectedEl.textContent = 'Selected: ' + (o.label || o.id);
            render(g);
        };
        outcomesEl.appendChild(div);
    });
    tickTimer();
}

closeBtn.onclick = function () {
    nui('close');
    hideApp();
};

placeBtn.onclick = function () {
    if (!currentGame) {
        selectedEl.textContent = 'No active show';
        return;
    }
    if (!selected) {
        selectedEl.textContent = 'Pick an outcome first';
        return;
    }
    if (currentGame.state !== 'ROUND_BETTING') {
        selectedEl.textContent = 'Bets are not open';
        return;
    }
    const amount = Number(amountEl.value || 0);
    nui('placeBet', {
        gameId: currentGame.id,
        outcomeId: selected,
        amount: amount
    });
};

window.addEventListener('message', function (e) {
    const msg = e.data || {};
    const action = msg.action;
    const data = msg.data || {};

    if (action === 'show') {
        setTimerFromSync(data.timeLeft);
        showApp(data);
    }
    if (action === 'sync') {
        currentGame = data;
        setTimerFromSync(data.timeLeft);
        if (!app.classList.contains('hidden')) render(data);
    }
    if (action === 'hide') {
        hideApp();
        leaveEl.classList.add('hidden');
    }
    if (action === 'hype') {
        hypeEl.textContent = data.text || '';
        const poster = document.querySelector('.poster');
        if (poster) {
            poster.classList.add('shake');
            setTimeout(function () { poster.classList.remove('shake'); }, 500);
        }
    }
    if (action === 'warn') {
        hypeEl.textContent = data.secondsLeft + 's LEFT TO BET';
    }
    if (action === 'execute') {
        const o = data.outcome || {};
        hypeEl.textContent = 'Outcome: ' + (o.label || o.id || '???');
    }
    if (action === 'result') {
        const winner = data.label || data.winningOutcome || '???';
        hypeEl.textContent = 'WINNER: ' + winner;
    }
    if (action === 'leaveWarning') {
        leaveEl.textContent = 'RETURN TO THE CAGE: ' + data.seconds + 's';
        leaveEl.classList.remove('hidden');
    }
    if (action === 'leaveReturn') {
        leaveEl.classList.add('hidden');
    }
});

document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') {
        nui('close');
        hideApp();
    }
});

// RSOB voice audio patch - added by RS OutcomeBets Audio Director.
(function () {
    function cleanSoundFile(file) {
        if (!file) return null;
        var f = String(file).replace(/\\/g, '/').split('/').pop();
        if (!/\.ogg$/i.test(f)) return null;
        return f;
    }

    window.addEventListener('message', function (e) {
        var data = e.data || {};
        if (data.action !== 'playVoice') return;

        var file = cleanSoundFile(data.file);
        if (!file) return;

        try {
            var audio = new Audio('../sounds/' + file);
            audio.volume = Math.max(0, Math.min(1, Number(data.volume) || 0.7));
            audio.addEventListener('ended', function () { audio.remove(); });
            setTimeout(function () { try { audio.remove(); } catch (err) {} }, 8000);
            var p = audio.play();
            if (p && p.catch) p.catch(function () {});
        } catch (err) {}
    });
})();
