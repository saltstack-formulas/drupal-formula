{% from "drupal/map.jinja" import drupal with context %}

include:
    - php

# use archive.extracted to get drupal archive installed New in version 2014.1.0.
{% if grains['saltversion'] > '2014.7.0' %}
unzip:
  pkg.installed:
    - name: unzip

drupal:
  archive.extracted:
    - name: {{ drupal.home }}/
    - source: http://ftp.drupal.org/files/projects/drupal-{{ drupal.version }}.tar.gz
    - source_hash: {{ drupal.source_hash }}
    - archive_format: tar
    - tar_options: zv
    - if_missing: {{ drupal.home }}/drupal-{{ drupal.version }}
    - unless: ls {{ drupal.home }}/{{ drupal.name }}/sites/default/default.settings.php
{% else %}
# get drupal tarball on system from drupal.org
drupal:
    file.managed:
        - unless: ls {{ drupal.home }}/{{ drupal.name }}/sites/default/default.settings.php
        - name: /tmp/drupal-{{ drupal.version }}.tar.gz
        - source: http://ftp.drupal.org/files/projects/drupal-{{ drupal.version }}.tar.gz
        - source_hash: {{ drupal.source_hash }}
        - user: {{ drupal.user }}
        - group: {{ drupal.group }}

# extract drupal tarball
extract-drupal:
    module.run:
        - name: archive.tar
        - options: zxf
        - tarfile: /tmp/drupal-{{ drupal.version }}.tar.gz
        - dest: {{ drupal.home }}
        - archive_user: {{ drupal.user }}
        - unless: ls {{ drupal.home }}/{{ drupal.name }}/sites/default/default.settings.php
{% endif %}

# rename drupal folder to site name
rename-drupal:
    file.rename:
        - name: {{ drupal.home }}/{{ drupal.name }}
        - source: {{ drupal.home }}/drupal-{{ drupal.version }}
        - unless: ls {{ drupal.home }}/{{ drupal.name }}/sites/default/default.settings.php

{% if drupal.fix_permissions %}
# create files dir not present in tarball
files:
  file.directory:
    - name: {{ drupal.home }}/{{ drupal.name }}/sites/default/files
    - user: {{ drupal.user }}
    - group: {{ drupal.group }}
    - mode: 0770
    - makedirs: True

# Securing file permissions and ownership on drupal sites
# script from https://www.drupal.org/node/244924
/usr/local/bin/fix-permissions.sh:
  cmd.wait:
    - name: /usr/local/bin/fix-permissions.sh --drupal_path={{ drupal.home }}/{{ drupal.name }} --drupal_user={{ drupal.user }} --httpd_group={{ drupal.group }}
    - order: last
    - watch:
      - file: {{ drupal.home }}/{{ drupal.name }}
  file.managed:
    - source: salt://drupal/files/fix-permissions.sh
    - user: root
    - group: root
    - mode: 0755

{% endif %}
