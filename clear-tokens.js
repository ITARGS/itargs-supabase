/**
 * ONE-TIME FIX: Clear all cached auth tokens
 * 
 * Add this to your browser console and run it once:
 * This will clear all Supabase auth data and force a fresh login
 */

// Clear all Supabase auth data from localStorage
Object.keys(localStorage).forEach(key => {
    if (key.includes('supabase') || key.includes('auth')) {
        localStorage.removeItem(key);
        console.log('Cleared:', key);
    }
});

// Clear sessionStorage too
Object.keys(sessionStorage).forEach(key => {
    if (key.includes('supabase') || key.includes('auth')) {
        sessionStorage.removeItem(key);
        console.log('Cleared:', key);
    }
});

console.log('✅ All auth tokens cleared! Refreshing page...');
setTimeout(() => window.location.reload(), 1000);
