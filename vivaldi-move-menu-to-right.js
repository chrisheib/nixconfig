console.log('[mv-menu] script loaded');
try {
    (function () {

        'use strict';

        function moveMenuOnce() {
            try {
                console.log('[mv-menu] try move menu');
                const menu = document.querySelector('#header #titlebar button.vivaldi, button.vivaldi');
                const addr = document.querySelector('.toolbar-addressbar.toolbar, .toolbar-addressbar');
                if (!menu || !addr) return false;
                if (addr.contains(menu)) return true;
                // move and give it high order so it sits at the right end
                addr.appendChild(menu);
                menu.style.order = '999';
                menu.style.marginLeft = '6px';
                return true;
            } catch (e) {
                return false;
            }
        }

        // Try immediately and a few times with delays (UI sometimes builds async)
        const tries = [0, 150, 400, 800, 1500];
        tries.forEach((t) => setTimeout(moveMenuOnce, t));

        // Keep it in place when Vivaldi rearranges DOM (fullscreen, profile changes, etc.)
        const mo = new MutationObserver(() => moveMenuOnce());
        // observe header and body so changes re-run the move
        const header = document.querySelector('#header') || document.body;
        if (header) mo.observe(header, { childList: true, subtree: true, attributes: true });

        // fullscreen / resize fallback
        document.addEventListener('fullscreenchange', () => setTimeout(moveMenuOnce, 200));
        window.addEventListener('resize', () => setTimeout(moveMenuOnce, 100));
    })();
} catch (err) {
    console.error('[mv-menu] exception:', err && err.stack || err);
}