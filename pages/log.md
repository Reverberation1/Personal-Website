---
layout: default
title: Log
permalink: /log/
---

# Log

<p class="scramble-text">Short notes, newest first.</p>

{% assign entries = site.log | sort: 'date' | reverse %}
{% if entries.size > 0 %}
<ul class="entry-list">
  {% for entry in entries %}
  <li class="entry-row">
    <a class="entry-link" href="{{ entry.url | relative_url }}">{{ entry.title }}</a>
    <time class="entry-date" datetime="{{ entry.date | date: '%Y-%m-%d' }}">{{ entry.date | date: '%Y-%m-%d' }}</time>
  </li>
  {% endfor %}
</ul>
{% else %}
<p class="empty-state">Nothing here yet.</p>
{% endif %}
