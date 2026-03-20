// Theme Toggle Functionality
// Toggles between dark and light mode using Gruvbox color scheme
// Uses data-theme attribute for Jekyll compatibility

(function() {
    'use strict';
    
    // Get theme toggle button
    const themeToggle = document.getElementById('theme-toggle');
    const themeIcon = themeToggle?.querySelector('.theme-icon');
    const html = document.documentElement;
    
    // Get saved theme preference or default to dark
    const getSavedTheme = () => {
        return localStorage.getItem('theme') || 'dark';
    };
    
    // Save theme preference
    const saveTheme = (theme) => {
        localStorage.setItem('theme', theme);
    };
    
    // Apply theme
    const applyTheme = (theme) => {
        if (theme === 'light') {
            html.setAttribute('data-theme', 'light');
            html.classList.add('light-mode'); // Keep for backward compatibility
            if (themeIcon) themeIcon.textContent = '☀️';
        } else {
            html.setAttribute('data-theme', 'dark');
            html.classList.remove('light-mode');
            if (themeIcon) themeIcon.textContent = '🌙';
        }
    };
    
    // Duration for theme transition (must match CSS)
    const THEME_TRANSITION_MS = 200;

    // Toggle theme with smooth animation
    const toggleTheme = () => {
        const currentTheme = html.getAttribute('data-theme') || (html.classList.contains('light-mode') ? 'light' : 'dark');
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';

        // Enable smooth transition for this change only (no transition on initial load)
        html.classList.add('theme-transitioning');

        applyTheme(newTheme);
        saveTheme(newTheme);

        // Remove transition class after animation so page loads stay instant
        setTimeout(() => {
            html.classList.remove('theme-transitioning');
        }, THEME_TRANSITION_MS);
    };
    
    // Initialize theme on page load
    const initTheme = () => {
        const savedTheme = getSavedTheme();
        applyTheme(savedTheme);
    };
    
    // Set up event listener
    if (themeToggle) {
        themeToggle.addEventListener('click', toggleTheme);
    }
    
    // Apply saved theme when page loads
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initTheme);
    } else {
        initTheme();
    }
})();
