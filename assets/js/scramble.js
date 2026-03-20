// Text Scramble Animation on Hover and on Load
// Creates a letter-scrambling effect when hovering over navigation links and name
// On page load: nav and name scramble in from left to right

(function() {
    'use strict';
    
    // Characters to use for scrambling (alphanumeric + some symbols)
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
    
    // Store active timers to prevent multiple animations
    const activeTimers = new WeakMap();
    
    function randomChars(length) {
        let s = '';
        for (let i = 0; i < length; i++) s += chars[Math.floor(Math.random() * chars.length)];
        return s;
    }
    
    // Scramble animation (smooth reveal on hover)
    function scrambleText(element, originalText, duration = 1000, useBrackets = false) {
        if (activeTimers.has(element)) clearInterval(activeTimers.get(element));
        const iterations = 20;
        const interval = duration / iterations;
        let iteration = 0;
        const timer = setInterval(() => {
            const scrambled = originalText.split('').map((char, index) => {
                if (char === ' ') return char;
                if (index < iteration) return originalText[index];
                return chars[Math.floor(Math.random() * chars.length)];
            }).join('');
            if (useBrackets) element.textContent = '[' + scrambled + ']';
            else element.textContent = scrambled;
            if (iteration >= originalText.length) {
                clearInterval(timer);
                activeTimers.delete(element);
                element.textContent = useBrackets ? '[' + originalText + ']' : originalText;
                return;
            }
            iteration += 1 / 3;
        }, interval);
        activeTimers.set(element, timer);
    }
    
    // Titles: more varied scramble (faster updates + richer character set)
    const TITLE_SCRAMBLE_DURATION_MS = 420;
    const TITLE_SCRAMBLE_FRAME_MS = 32;
    const TITLE_HOVER_SCRAMBLE_MS = 450;
    const titleScrambleChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*<>?/\\{}[]|~`+=_-';

    function scrambleWordForDuration(element, word, durationMs, cancelToken) {
        const len = word.length;
        const start = performance.now();
        let cancelled = false;
        if (cancelToken) cancelToken.cancel = function() { cancelled = true; };
        const pool = titleScrambleChars;
        function randomCharAt(i) {
            if (word[i] === ' ') return ' ';
            return pool[Math.floor(Math.random() * pool.length)];
        }
        function tick(now) {
            now = now || performance.now();
            if (cancelled) {
                element.textContent = word;
                return;
            }
            const elapsed = now - start;
            if (elapsed >= durationMs) {
                element.textContent = word;
                return;
            }
            const progress = Math.min(1, elapsed / durationMs);
            const revealed = Math.min(len, Math.floor(progress * (len + 0.99)));
            let out = word.slice(0, revealed);
            for (let i = revealed; i < len; i++) out += randomCharAt(i);
            element.textContent = out;
            setTimeout(function() { tick(performance.now()); }, TITLE_SCRAMBLE_FRAME_MS);
        }
        tick(start);
    }
    
    // Name on load: letter-by-letter reveal
    const SCRAMBLE_FRAME_MS = 45;
    const LETTER_FIX_MS = 70;
    const NAME_FRAME_MS = 32;
    const NAME_LETTER_FIX_MS = 48;
    
    function revealLetterByLetter(element, text, useBrackets, onComplete, reserveSpace, letterFixMs, frameMs) {
        const len = text.length;
        let revealed = 0;
        let letterStart = 0;
        const fixMs = letterFixMs != null ? letterFixMs : LETTER_FIX_MS;
        const frame = frameMs != null ? frameMs : SCRAMBLE_FRAME_MS;
        
        function randomCharFor(pos) {
            if (text[pos] === ' ') return ' ';
            return chars[Math.floor(Math.random() * chars.length)];
        }
        
        function tick(now) {
            now = now || performance.now();
            let out = text.slice(0, revealed);
            if (revealed < len) {
                out += randomCharFor(revealed);
            }
            if (revealed >= len) {
                element.textContent = useBrackets ? '[' + text + ']' : text;
                if (onComplete) onComplete();
                return;
            }
            if (reserveSpace) {
                var visible = useBrackets ? '[' + out + ']' : out;
                var reserve = text.slice(revealed + 1);
                element.innerHTML = '<span>' + visible + '</span><span class="nav-link-reserve" aria-hidden="true">' + reserve + '</span>';
            } else {
                if (useBrackets) element.textContent = '[' + out + ']';
                else element.textContent = out;
            }
            if (now - letterStart >= fixMs) {
                revealed += 1;
                letterStart = now;
            }
            setTimeout(function() { tick(performance.now()); }, frame);
        }
        letterStart = performance.now();
        tick(letterStart);
    }
    
    const SCRAMBLE_NAV_CLICKED_KEY = 'scrambleNavClicked';

    // Load: only the nav title that was clicked scrambles after navigation; on refresh/first load, all scramble
    // Name and page h1 always scramble. Run after first paint (defer one frame).
    function runLoadScramble() {
        function run() {
            const navItems = document.querySelectorAll('.nav-link[data-text], .nav-link-current[data-text]');
            let onlyScrambleText = null;
            try {
                onlyScrambleText = sessionStorage.getItem(SCRAMBLE_NAV_CLICKED_KEY);
                if (onlyScrambleText) sessionStorage.removeItem(SCRAMBLE_NAV_CLICKED_KEY);
            } catch (e) {}

            navItems.forEach(item => {
                const wordEl = item.querySelector('.nav-link-word');
                const word = item.getAttribute('data-text');
                if (!wordEl || !word) return;
                if (onlyScrambleText && word !== onlyScrambleText) return;
                wordEl.textContent = '';
                scrambleWordForDuration(wordEl, word, TITLE_SCRAMBLE_DURATION_MS);
            });

            const nameEl = document.querySelector('.name');
            if (nameEl) {
                const nameOriginal = nameEl.textContent.trim();
                if (nameOriginal) {
                    nameEl.textContent = '';
                    revealLetterByLetter(nameEl, nameOriginal, false, undefined, false, NAME_LETTER_FIX_MS, NAME_FRAME_MS);
                }
            }

            document.querySelectorAll('.main > h1:not(.name)').forEach(function(el) {
                const text = el.textContent.trim();
                if (text) {
                    el.textContent = '';
                    revealLetterByLetter(el, text, false, undefined, false, NAME_LETTER_FIX_MS, NAME_FRAME_MS);
                }
            });

            document.querySelectorAll('.scramble-text').forEach(function(el) {
                const text = el.textContent.trim();
                if (text) {
                    el.textContent = '';
                    revealLetterByLetter(el, text, false, undefined, false, NAME_LETTER_FIX_MS, NAME_FRAME_MS);
                }
            });
        }
        requestAnimationFrame(function() {
            requestAnimationFrame(run);
        });
    }
    
    // Initialize on all navigation links, name, and first content h1 per page
    function initScramble() {
        // Navigation: all items (links + current page span) get hover scramble; only links get click
        const navItems = document.querySelectorAll('.nav-link[data-text], .nav-link-current[data-text]');
        navItems.forEach(item => {
            const cancelToken = {};
            if (item.tagName === 'A') {
                item.addEventListener('click', function() {
                    try {
                        sessionStorage.setItem(SCRAMBLE_NAV_CLICKED_KEY, this.getAttribute('data-text'));
                    } catch (e) {}
                });
            }
            item.addEventListener('mouseenter', function() {
                const wordEl = this.querySelector('.nav-link-word');
                const word = this.getAttribute('data-text');
                if (wordEl && word) {
                    if (cancelToken.cancel) cancelToken.cancel();
                    scrambleWordForDuration(wordEl, word, TITLE_HOVER_SCRAMBLE_MS, cancelToken);
                }
            });
            item.addEventListener('mouseleave', function() {
                if (cancelToken.cancel) cancelToken.cancel();
                const wordEl = this.querySelector('.nav-link-word');
                const word = this.getAttribute('data-text');
                if (wordEl && word) wordEl.textContent = word;
            });
        });
        
        document.querySelectorAll('.name').forEach(function(el) {
            const text = el.textContent.trim();
            if (text) {
                el.addEventListener('mouseenter', function() {
                    scrambleText(this, text, 450, false);
                });
            }
        });

        document.querySelectorAll('.main > h1:not(.name)').forEach(function(el) {
            const text = el.textContent.trim();
            if (text) {
                el.addEventListener('mouseenter', function() {
                    scrambleText(this, text, 450, false);
                });
            }
        });

        document.querySelectorAll('.scramble-text').forEach(function(el) {
            const text = el.textContent.trim();
            if (text) {
                el.addEventListener('mouseenter', function() {
                    scrambleText(this, text, 450, false);
                });
            }
        });
        
        runLoadScramble();
    }
    
    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initScramble);
    } else {
        initScramble();
    }
})();
