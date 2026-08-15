const app = document.getElementById('app');
const type = app.dataset.case;
const labels = {
  without: ['Case 1 · No anti-affinity', 'Both replicas share worker-1', 'Without a placement rule, replicas can land on the same feasible worker.'],
  required: ['Case 2 · Required pod anti-affinity', 'One replica per worker', 'Matching app: web Pods cannot share a hostname.'],
  ignored: ['Case 3 · Ignored during execution', 'A topology label changes later', 'The rule is enforced for new Pods, not by evicting existing Pods.']
}[type];
const state = { replicas: 2, failed1: false, failed2: false, changed: false };
const pod = (name, status = 'Running') => `<div class="pod ${status.toLowerCase()}">${name}</div>`;
const node = (name, failed, pods, label, changed = false) => `<article class="node ${failed ? 'failed' : ''} ${changed ? 'changed' : ''}"><div class="node-top"><span class="node-name"><i class="node-dot"></i>${name}</span></div>${label ? `<p class="label">${label}</p>` : ''}<div class="pods">${pods || '<div class="empty">no web Pods</div>'}</div></article>`;

function render() {
  const protectedMode = type !== 'without';
  const pods1 = protectedMode ? pod('web-1', state.failed1 ? 'Lost' : 'Running') : Array.from({ length: state.replicas }, (_, i) => pod(`web-${i + 1}`, state.failed1 ? 'Lost' : 'Running')).join('');
  const pods2 = protectedMode ? pod('web-2', state.failed2 ? 'Lost' : 'Running') : '';
  const unavailable = Number(state.failed1) + Number(state.failed2);
  const pending = protectedMode ? Math.max(0, state.replicas - 2) + unavailable : 0;
  const available = protectedMode ? 2 - unavailable : state.failed1 ? 0 : state.replicas;
  const queue = pending ? `<div class="scheduler-queue"><strong>Pending</strong><span>${pending} replacement${pending > 1 ? 's' : ''}</span></div>` : '';
  const label2 = type === 'ignored' && state.changed ? 'topology: worker-1 (changed)' : 'topology: worker-2';
  const message = type === 'ignored' && state.changed ? `<strong>web service: ${available} / ${state.replicas} Running</strong> · no Pods evicted` : pending ? `<strong>web service: ${available} / ${state.replicas} Running</strong> · ${pending} Pending` : `<strong>web service: ${available} / ${state.replicas} Running</strong>`;
  app.innerHTML = `<header class="page-head"><div><p class="eyebrow">${labels[0]}</p><h1>${labels[1]}</h1><p class="case-copy">${labels[2]}</p></div><a class="menu-card" href="../visualization.html"><span>Main menu</span><strong>Choose a case</strong><small>Lab 01 scenarios</small></a></header><div class="controls"><button data-action="scale">Scale +1</button><button class="fail" data-action="fail1">Fail w1</button><button class="fail" data-action="fail2">Fail w2</button>${type === 'ignored' ? '<button data-action="change">Change label</button>' : ''}<button data-action="reset">Reset</button></div><section class="cluster"><div class="cluster-head"><strong>web service</strong><span>${available} / ${state.replicas} Running</span></div><div class="nodes">${node('worker-1', state.failed1, pods1, '')}${node('worker-2', state.failed2, pods2, type === 'ignored' && state.changed ? label2 : '', type === 'ignored' && state.changed)}</div>${queue}</section><p class="outcome ${available === 0 ? 'down' : type === 'ignored' && state.changed ? 'note' : ''}">${message}</p><nav class="pager">${type === 'without' ? '<a href="../visualization.html">← Main menu</a>' : '<a href="without-anti-affinity.html">← Case 1</a>'}${type === 'ignored' ? '<a href="../visualization.html">Main menu ↑</a>' : `<a href="${type === 'without' ? 'required-pod-anti-affinity.html' : 'ignored-during-execution.html'}">Next case →</a>`}</nav>`;
  app.querySelectorAll('[data-action]').forEach((button) => { button.disabled = (button.dataset.action === 'scale' && state.replicas === 4) || (button.dataset.action === 'fail1' && state.failed1) || (button.dataset.action === 'fail2' && state.failed2) || (button.dataset.action === 'change' && state.changed); button.onclick = () => { const action = button.dataset.action; if (action === 'scale') state.replicas++; if (action === 'fail1') state.failed1 = true; if (action === 'fail2') state.failed2 = true; if (action === 'change') state.changed = true; if (action === 'reset') Object.assign(state, { replicas: 2, failed1: false, failed2: false, changed: false }); render(); }; });
}
render();
