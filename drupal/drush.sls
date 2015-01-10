{% from "drupal/map.jinja" import drupal with context %}

include:
  - php.pear

channel-discover:
  cmd.run:
    - name: pear channel-discover pear.drush.org
    - unless: pear list-channels |grep pear.drush.org

drush:
  pecl.installed:
    - name: drush/drush
    - default: True
    - require:
      - pkg: php-pear
      - cmd: channel-discover

drush-update:
  cmd.wait:
    - name: drush
    - unless: test -d /usr/share/php/drush/lib/Console_Table-1.1.3
    - order: last
    - watch:
        - pecl: drush
