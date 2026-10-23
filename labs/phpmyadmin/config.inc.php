<?php
$cfg['blowfish_secret'] = 'p2s-lab-phpmyadmin-blowfish-secret-32ch';
$i = 0;
$i++;
$cfg['Servers'][$i]['host'] = 'db';
$cfg['Servers'][$i]['port'] = '3306';
$cfg['Servers'][$i]['user'] = 'root';
$cfg['Servers'][$i]['password'] = 'rootpass123';
$cfg['Servers'][$i]['auth_type'] = 'config';
$cfg['Servers'][$i]['AllowNoPassword'] = true;
$cfg['TempDir'] = '/var/www/html/tmp';
