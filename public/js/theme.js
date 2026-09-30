export function initTheme() {
  const btnTheme = document.getElementById('btn-theme');
  
  // Baca localStorage
  let savedTheme = 'light';
  try {
    savedTheme = localStorage.getItem('theme');
  } catch (e) {
    // Abaikan jika localStorage diblokir
  }

  // Set initial theme
  if (savedTheme === 'dark' || savedTheme === 'light') {
    document.documentElement.dataset.theme = savedTheme;
  }

  // Toggle theme
  btnTheme.addEventListener('click', () => {
    let currentTheme = document.documentElement.dataset.theme;
    
    // Jika tidak ada di dataset, periksa preferensi media query
    if (!currentTheme) {
      currentTheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    }

    const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
    document.documentElement.dataset.theme = newTheme;

    try {
      localStorage.setItem('theme', newTheme);
    } catch (e) {
      // Abaikan
    }
  });
}
