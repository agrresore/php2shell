<?php
define('DB_NAME',     getenv('WORDPRESS_DB_NAME')     ?: 'wordpress');
define('DB_USER',     getenv('WORDPRESS_DB_USER')     ?: 'wpuser');
define('DB_PASSWORD', getenv('WORDPRESS_DB_PASSWORD') ?: 'wppass123');
define('DB_HOST',     getenv('WORDPRESS_DB_HOST')     ?: 'db');
define('DB_CHARSET',  'utf8mb4');
define('DB_COLLATE',  '');

define('AUTH_KEY',         'p2s-lab-key-1');
define('SECURE_AUTH_KEY',  'p2s-lab-key-2');
define('LOGGED_IN_KEY',    'p2s-lab-key-3');
define('NONCE_KEY',        'p2s-lab-key-4');
define('AUTH_SALT',        'p2s-lab-salt-1');
define('SECURE_AUTH_SALT', 'p2s-lab-salt-2');
define('LOGGED_IN_SALT',   'p2s-lab-salt-3');
define('NONCE_SALT',       'p2s-lab-salt-4');

$table_prefix = 'wp_';

define('WP_DEBUG', false);
define('ABSPATH', __DIR__ . '/');

require_once ABSPATH . 'wp-settings.php';
