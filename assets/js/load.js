// Content Loading Animation
// Provides smooth fade-in effect for content on page load

(function() {
    'use strict';
    
    // Wait for DOM to be ready
    const initLoadAnimation = () => {
        const main = document.querySelector('.main');
        
        if (main) {
            // Content is already set to opacity: 0 in CSS
            // This script ensures it fades in smoothly
            // The CSS animation handles the actual fade-in
            // This is here for potential future enhancements
            
            // Optional: Add a subtle loading indicator
            // For now, we rely on CSS animation for simplicity
        }
    };
    
    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initLoadAnimation);
    } else {
        initLoadAnimation();
    }
})();
