{%- set apples = ["Gala", "Fuji", "Honeycrisp", "Red Delicious", "Granny Smith", "Pink Lady", "Jazz", "Ambrosia"] -%}
{% for i in apples %}
    {% if i != "Red Delicious" %}
        {{ i }}
    {% else %}
       I hate {{ i }}
    {% endif %}
{% endfor %}
 