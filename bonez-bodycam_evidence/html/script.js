// bonez-bodycam_evidence | html/script.js
// NUI: CfxTexture capture → MediaRecorder → WebM → Fivemanage upload.
// Evidence hub (clip browser) + player.

'use strict';

// ── Element refs ───────────────────────────────────────────────────────────
const viewer       = document.getElementById('viewer');
const footage      = document.getElementById('footage');
const overlayText  = document.getElementById('video-overlay-text');
const exportStatus = document.getElementById('export-status');
const elHeaderSub  = document.getElementById('header-sub');

const hubPage    = document.getElementById('hub-page');
const playerPage = document.getElementById('player-page');
const hubInput   = document.getElementById('hub-input');
const hubNotice  = document.getElementById('hub-notice');
const clipList   = document.getElementById('clip-list');

// ── Metadata element refs ──────────────────────────────────────────────────
const elUnit     = document.getElementById('meta-unit');
const elClipId   = document.getElementById('meta-clipid');
const elTrigger  = document.getElementById('meta-trigger');
const elDate     = document.getElementById('meta-date');
const elDuration = document.getElementById('meta-duration');
const elStatus   = document.getElementById('meta-status');

// ── Hub state ──────────────────────────────────────────────────────────────
var hubClips      = [];
var hubUnitId     = null;
var playerClip    = null;  // clip currently open in player

// ── Viewer/capture state ───────────────────────────────────────────────────
var currentClipId            = null;
var captureClipId            = null;
var captureGameCanvas        = null;
var captureOutputCanvas      = null;
var captureOutputCtx         = null;
var captureCompositeInterval = null;
var captureStream            = null;
var captureRecorder          = null;
var captureChunks            = [];

// ── Page switching ─────────────────────────────────────────────────────────

function showHub() {
    hubPage.classList.remove('hidden');
    playerPage.classList.add('hidden');
}

function showPlayer() {
    hubPage.classList.add('hidden');
    playerPage.classList.remove('hidden');
}

// ── Hub functions ──────────────────────────────────────────────────────────

function openHub() {
    viewer.classList.add('open');
    showHub();
    elHeaderSub.textContent = 'EVIDENCE HUB';
}

function renderClipList(clips) {
    hubClips    = clips || [];
    clipList.innerHTML = '';

    if (!hubClips.length) {
        hubNotice.textContent = 'No clips found for unit ' + (hubUnitId || '?') + '.';
        hubNotice.className = 'empty';
        return;
    }

    hubNotice.textContent = hubClips.length + ' clip(s) found for unit ' + hubUnitId + '.';
    hubNotice.className = 'found';

    hubClips.forEach(function (clip, i) {
        var row = document.createElement('div');
        row.className    = 'clip-row';
        row.dataset.index = i;

        // Trigger badge + row left-border class
        var badge = document.createElement('span');
        badge.className = 'clip-trigger';
        var t = (clip.trigger || '').toUpperCase();
        if      (t === 'CALLOUT')      { badge.classList.add('callout');  row.classList.add('trigger-callout'); }
        else if (t === 'TRACKING')     { badge.classList.add('tracking'); row.classList.add('trigger-tracking'); }
        else if (t === 'WEAPON_FIRED') { badge.classList.add('weapon');   row.classList.add('trigger-weapon'); }
        else                           { badge.classList.add('unknown');  row.classList.add('trigger-unknown'); }
        badge.textContent = t || '?';
        row.appendChild(badge);

        // Date + sub-line
        var info = document.createElement('div');
        info.className = 'clip-info';

        var dateEl = document.createElement('div');
        dateEl.className   = 'clip-date';
        dateEl.textContent = formatTimestamp(clip.startTime);

        var subEl = document.createElement('div');
        subEl.className   = 'clip-sub';
        subEl.textContent =
            (clip.serviceType || 'N/A').toUpperCase() +
            ' \u2014 Unit ' + (clip.unitId || '?');

        info.appendChild(dateEl);
        info.appendChild(subEl);
        row.appendChild(info);

        // Duration
        var durEl = document.createElement('div');
        durEl.className   = 'clip-duration';
        durEl.textContent = formatDuration(clip.duration);
        row.appendChild(durEl);

        // Status pill
        var statusEl = document.createElement('div');
        statusEl.className = 'clip-status';
        var s = (clip.uploadStatus || '').toLowerCase();
        if      (s === 'uploaded') statusEl.classList.add('uploaded');
        else if (s === 'pending')  statusEl.classList.add('pending');
        else if (s === 'failed')   statusEl.classList.add('failed');
        else if (s === 'no_retry') statusEl.classList.add('no-retry');
        statusEl.textContent = (clip.uploadStatus || 'N/A').toUpperCase();
        row.appendChild(statusEl);

        row.addEventListener('click', function () {
            openClipFromHub(hubClips[parseInt(this.dataset.index)]);
        });

        clipList.appendChild(row);
    });
}

function openClipFromHub(clip) {
    playerClip = clip;
    populatePlayer(clip.fivemanageUrl || '', clip);
    showPlayer();
}

function goBackToHub() {
    footage.pause();
    footage.src = '';
    playerClip  = null;
    currentClipId = null;
    showHub();
    if (hubUnitId) {
        elHeaderSub.textContent = 'UNIT ' + hubUnitId + ' \u2014 ' + hubClips.length + ' CLIP(S)';
    } else {
        elHeaderSub.textContent = 'EVIDENCE HUB';
    }
}

// ── Hub search ─────────────────────────────────────────────────────────────

document.getElementById('hub-search-btn').addEventListener('click', function () {
    var val = hubInput.value.trim();
    if (!val) {
        hubNotice.textContent = 'Please enter a player ID.';
        return;
    }
    hubUnitId          = val;
    hubClips           = [];
    clipList.innerHTML = '';
    hubNotice.textContent = 'Searching\u2026';
    hubNotice.className = 'searching';
    fetch('https://bonez-bodycam_evidence/searchClips', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ unitId: val }),
    });
});

hubInput.addEventListener('keydown', function (e) {
    if (e.key === 'Enter') document.getElementById('hub-search-btn').click();
});

// ── Clip deleted (forwarded from Lua net event) ────────────────────────────

function onClipDeleted(clipId, success) {
    if (!success) return;
    // Remove from local list
    hubClips = hubClips.filter(function (c) { return c.clipId !== clipId; });
    // If the deleted clip is open in player, go back to hub
    if (playerClip && playerClip.clipId === clipId) {
        goBackToHub();
    }
    // Re-render list (updates count in notice too)
    renderClipList(hubClips);
}

// ── Player action buttons ──────────────────────────────────────────────────

document.getElementById('btn-back').addEventListener('click', goBackToHub);

document.getElementById('btn-export').addEventListener('click', function () {
    if (!playerClip) return;
    fetch('https://bonez-bodycam_evidence/exportToChat', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(playerClip),
    });
});

document.getElementById('btn-delete').addEventListener('click', function () {
    if (!playerClip) return;
    fetch('https://bonez-bodycam_evidence/deleteClip', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ clipId: playerClip.clipId }),
    });
});

// ── Capture functions ──────────────────────────────────────────────────────

function startCapture(data) {
    var clipId = data.clipId;
    var width  = data.width  || 1280;
    var height = data.height || 720;
    var fps    = data.fps    || 20;

    captureClipId = clipId;
    captureChunks = [];

    // Game texture renders into this canvas via CfxTexture/Three.js
    captureGameCanvas        = document.createElement('canvas');
    captureGameCanvas.width  = width;
    captureGameCanvas.height = height;

    // Square output canvas — center-cropped 1:1 for bodycam look
    var cropSize               = Math.min(width, height);
    captureOutputCanvas        = document.createElement('canvas');
    captureOutputCanvas.width  = cropSize;
    captureOutputCanvas.height = cropSize;
    captureOutputCtx           = captureOutputCanvas.getContext('2d');

    if (window.MainRender) {
        window.MainRender.renderToTarget(captureGameCanvas);
    }

    var sx = (width  - cropSize) / 2;
    var sy = (height - cropSize) / 2;
    captureCompositeInterval = setInterval(function () {
        captureOutputCtx.drawImage(captureGameCanvas, sx, sy, cropSize, cropSize, 0, 0, cropSize, cropSize);
    }, 15);

    var mimeType = MediaRecorder.isTypeSupported('video/webm;codecs=vp9')
        ? 'video/webm;codecs=vp9'
        : MediaRecorder.isTypeSupported('video/webm;codecs=vp8')
        ? 'video/webm;codecs=vp8'
        : 'video/webm';

    captureStream   = captureOutputCanvas.captureStream(fps);
    captureRecorder = new MediaRecorder(captureStream, {
        mimeType:           mimeType,
        videoBitsPerSecond: 2500000,
    });

    captureRecorder.ondataavailable = function (e) {
        if (e.data && e.data.size > 0) captureChunks.push(e.data);
    };
    captureRecorder.onstop = function () {
        handleCaptureStop(captureClipId);
    };

    captureRecorder.start(1000);
}

function stopCapture() {
    clearInterval(captureCompositeInterval);
    captureCompositeInterval = null;

    if (window.MainRender) {
        window.MainRender.stop();
    }

    if (captureRecorder && captureRecorder.state !== 'inactive') {
        captureRecorder.stop();
    }

    captureGameCanvas = null;
}

async function handleCaptureStop(clipId) {
    var chunks = captureChunks.slice();
    captureChunks       = [];
    captureClipId       = null;
    captureRecorder     = null;
    captureStream       = null;
    captureOutputCanvas = null;
    captureOutputCtx    = null;

    if (!chunks.length) {
        console.warn('[BCE] handleCaptureStop: no chunks for clip', clipId);
        return;
    }

    var blob = new Blob(chunks, { type: 'video/webm' });

    if (currentClipId === clipId) {
        setExportStatus('Uploading recording\u2026', false);
    }

    try {
        var presignedUrl = await getVideoPresignedUrl(clipId);
        var videoUrl     = await uploadWebM(blob, presignedUrl);
        await saveVideoUrlToServer(clipId, videoUrl);

        if (currentClipId === clipId) {
            setExportStatus('');
            overlayText.classList.remove('show');
            footage.src = videoUrl;
            footage.load();
            footage.play().catch(function () {});
        }
    } catch (err) {
        var msg = err && err.message ? err.message : String(err);
        console.error('[BCE] Upload failed for clip', clipId, msg);
        if (currentClipId === clipId) {
            setExportStatus('\u26A0 Upload failed: ' + msg, true);
        }
    }
}

// ── Upload helpers ─────────────────────────────────────────────────────────

function getVideoPresignedUrl(clipId) {
    return fetch('https://bonez-bodycam_evidence/getVideoPresignedUrl', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ clipId: clipId }),
    })
    .then(function (r) { return r.json(); })
    .then(function (d) {
        if (d && d.url) return d.url;
        throw new Error(d && d.error ? d.error : 'No presigned URL returned');
    });
}

function uploadWebM(blob, presignedUrl) {
    var fd = new FormData();
    fd.append('file', blob, 'bodycam.webm');
    return fetch(presignedUrl, { method: 'POST', body: fd })
        .then(function (r) { return r.text(); })
        .then(function (text) {
            var data;
            try { data = JSON.parse(text); } catch (e) {
                throw new Error('Invalid Fivemanage response: ' + text.slice(0, 120));
            }
            var url = data && data.data && data.data.url;
            if (!url) throw new Error('No URL in Fivemanage response');
            return url;
        });
}

function saveVideoUrlToServer(clipId, url) {
    return fetch('https://bonez-bodycam_evidence/saveVideoUrl', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ clipId: clipId, url: url }),
    }).then(function (r) { return r.json(); });
}

// ── Helpers ────────────────────────────────────────────────────────────────

function formatTimestamp(ts) {
    if (!ts) return 'N/A';
    var d = new Date(ts * 1000);
    return d.toISOString().replace('T', ' ').substring(0, 19);
}

function formatDuration(seconds) {
    if (!seconds || seconds <= 0) return '0s';
    var m = Math.floor(seconds / 60);
    var s = Math.floor(seconds % 60);
    return m > 0 ? (m + 'm ' + s + 's') : (s + 's');
}

function setExportStatus(msg, isError) {
    exportStatus.textContent = msg;
    exportStatus.classList.toggle('show', !!msg);
    exportStatus.classList.toggle('error', !!isError);
}

function setStatusColor(el, status) {
    el.className = 'meta-value';
    if (!status) return;
    var s = status.toLowerCase();
    if      (s === 'uploaded')  el.classList.add('green');
    else if (s === 'failed')    el.classList.add('red');
    else if (s === 'pending')   el.classList.add('yellow');
    else if (s === 'no_frames') el.classList.add('yellow');
    else if (s === 'no_retry')  el.classList.add('red');
}

function setTriggerColor(el, trigger) {
    el.className = 'meta-value';
    if (!trigger) return;
    var t = trigger.toUpperCase();
    if      (t === 'CALLOUT')      el.classList.add('accent');
    else if (t === 'TRACKING')     el.classList.add('green');
    else if (t === 'WEAPON_FIRED') el.classList.add('yellow');
}

// ── Populate player sidebar ────────────────────────────────────────────────

function populatePlayer(url, meta) {
    meta          = meta || {};
    currentClipId = meta.clipId || null;

    elUnit.textContent     = meta.unitId     || 'N/A';
    elClipId.textContent   = meta.clipId     || 'N/A';
    elDate.textContent     = formatTimestamp(meta.startTime);
    elDuration.textContent = formatDuration(meta.duration);

    elTrigger.textContent = (meta.trigger || 'N/A').toUpperCase();
    setTriggerColor(elTrigger, meta.trigger);

    elStatus.textContent = (meta.uploadStatus || 'N/A').toUpperCase();
    setStatusColor(elStatus, meta.uploadStatus);

    elHeaderSub.textContent =
        'UNIT: '         + (meta.unitId  || '?') +
        '  \u2502  '     + (meta.clipId  || '?').substring(0, 8) + '\u2026' +
        '  \u2502  '     + (meta.trigger || '?').toUpperCase();

    setExportStatus('');
    overlayText.classList.remove('show');
    footage.src           = '';
    footage.style.display = '';

    var status = (meta.uploadStatus || '').toLowerCase();

    if (url && url !== '') {
        footage.src = url;
        footage.load();
        footage.play().catch(function () {});
    } else if (status === 'processing') {
        overlayText.classList.add('show');
        overlayText.textContent = '[ ENCODING VIDEO \u2014 PLEASE WAIT ]';
        setExportStatus('Video is being processed\u2026', false);
    } else {
        overlayText.classList.add('show');
        if      (status === 'pending')   overlayText.textContent = '[ NO FOOTAGE \u2014 CLIP DID NOT COMPLETE RECORDING ]';
        else if (status === 'no_frames') overlayText.textContent = '[ NO FOOTAGE \u2014 NO FRAMES WERE CAPTURED ]';
        else if (status === 'abandoned') overlayText.textContent = '[ CLIP ABANDONED \u2014 RECORDING WAS INTERRUPTED ]';
        else                             overlayText.textContent = '[ NO FOOTAGE \u2014 METADATA ONLY ]';
    }
}

// ── Open / close viewer ────────────────────────────────────────────────────

// Direct player open (e.g. server-side triggered Viewer.Open call)
function openViewer(url, meta) {
    populatePlayer(url, meta);
    showPlayer();
    viewer.classList.add('open');
}

function closeViewer() {
    footage.pause();
    footage.src   = '';
    footage.style.display = '';
    viewer.classList.remove('open');
    playerClip    = null;
    currentClipId = null;
    // Reset hub state so it's clean on next open
    hubClips      = [];
    hubUnitId     = null;
    clipList.innerHTML    = '';
    hubNotice.textContent = 'Enter a unit ID above and press SEARCH to load clips.';
    hubNotice.className = '';
    hubInput.value        = '';
    showHub();
    fetch('https://bonez-bodycam_evidence/close', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({}),
    });
}

document.getElementById('btn-close').addEventListener('click', closeViewer);

document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') closeViewer();
});

// ── NUI message handler ────────────────────────────────────────────────────

window.addEventListener('message', function (event) {
    var data = event.data;
    if (!data || !data.action) return;

    switch (data.action) {
        case 'openHub':
            openHub();
            break;
        case 'open':
            openViewer(data.url, data.metadata);
            break;
        case 'close':
            closeViewer();
            break;
        case 'startCapture':
            startCapture(data);
            break;
        case 'stopCapture':
            stopCapture();
            break;
        case 'receiveClips':
            renderClipList(data.clips);
            break;
        case 'clipDeleted':
            onClipDeleted(data.clipId, data.success);
            break;
    }
});
