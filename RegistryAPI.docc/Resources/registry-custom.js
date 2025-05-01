// Custom JavaScript for Registry API Documentation

document.addEventListener('DOMContentLoaded', function() {
  // Add custom CSS
  const linkElement = document.createElement('link');
  linkElement.rel = 'stylesheet';
  linkElement.href = '../Resources/css/custom.css';
  document.head.appendChild(linkElement);
  
  // Enhance HTTP method displays
  document.querySelectorAll('code').forEach(function(element) {
    const text = element.textContent.trim();
    if (['GET', 'POST', 'PUT', 'DELETE', 'PATCH'].includes(text)) {
      element.classList.add('method-label');
      element.classList.add(`method-${text.toLowerCase()}`);
    }
  });
  
  // Add styling to HTTP status codes
  document.querySelectorAll('td').forEach(function(element) {
    const text = element.textContent.trim();
    if (text.match(/^[1-5][0-9][0-9]\s/)) {
      const statusCode = parseInt(text);
      if (statusCode >= 200 && statusCode < 300) {
        element.classList.add('status-success');
      } else if (statusCode >= 300 && statusCode < 400) {
        element.classList.add('status-redirect');
      } else if (statusCode >= 400 && statusCode < 500) {
        element.classList.add('status-client-error');
      } else if (statusCode >= 500) {
        element.classList.add('status-server-error');
      }
    }
  });
  
  // Enhance endpoint paths
  document.querySelectorAll('p').forEach(function(element) {
    if (element.textContent.includes('/{scope}/{name}')) {
      element.innerHTML = element.innerHTML.replace(
        /\/({\w+})\/({[\w-]+})/g, 
        '/<span class="endpoint-path">$1</span>/<span class="endpoint-path">$2</span>'
      );
    }
  });
  
  // Add information boxes
  document.querySelectorAll('p').forEach(function(element) {
    if (element.textContent.startsWith('Note:')) {
      element.classList.add('info-box');
    }
    if (element.textContent.startsWith('Warning:')) {
      element.classList.add('warning-box');
    }
  });
}); 
