{ pkgs, ... }:

let
  yaml = pkgs.formats.yaml { };
  # Reported by the owner. The usable capacity/model is not independently
  # known, so the charging-time calculation is explicitly an approximation.
  batteryCapacityKWh = 12.5;
  appliancePowerW = 2000;
  exportMarginW = 300;
  exportThresholdW = appliancePowerW + exportMarginW;
  soc = "sensor.__growatt_sph_id___ladezustand";
  charge = "sensor.__growatt_sph_id___batterieaufladung";
  discharge = "sensor.__growatt_sph_id___batterieentladung_w";
  gridImport = "sensor.__growatt_sph_id___netzbezug";
  gridExport = "sensor.__growatt_sph_id___netzeinspeisung";
  meanPower = "sensor.haus_batterie_nettoleistung_mittel";
  wp = "sensor.esphome_altherma___altherma_id___";
  wpBinary = "binary_sensor.esphome_altherma___altherma_id___";
  # The owner confirmed that the SPH meter covers the whole house, including
  # the other two PV plants. Do not add their generation again to this export.
  freshData = ''
    {% set ns = namespace(ok=true) %}
    {% set measured = as_timestamp(states('sensor.__growatt_sph_id___letzte_datenaktualisierung'), 0) %}
    {% set age = as_timestamp(now()) - measured %}
    {% if measured <= 0 or age < -60 or age > 900 %}
      {% set ns.ok = false %}
    {% endif %}
    {% for entity in ['${soc}', '${charge}', '${discharge}', '${gridImport}', '${gridExport}'] %}
      {% if not is_number(states(entity)) %}
        {% set ns.ok = false %}
      {% elif as_timestamp(now()) - as_timestamp(states[entity].last_reported, 0) > 900 %}
        {% set ns.ok = false %}
      {% endif %}
    {% endfor %}
    {{ ns.ok }}
  '';
  sensor =
    id: name: attrs:
    {
      inherit name;
      unique_id = id;
      default_entity_id = "sensor.${id}";
    }
    // attrs;
  timeToTarget =
    target: id: name:
    sensor id name {
      icon = "mdi:battery-clock-outline";
      state = ''
        {% set level = states('${soc}') | float(0) %}
        {% set current = states('${charge}') | float(0) - states('${discharge}') | float(0) %}
        {% set power = states('${meanPower}') | float(0) %}
        {% if not is_state('binary_sensor.haus_energiedaten_aktuell', 'on') %}
          Keine aktuellen Daten
        {% elif level >= ${toString target} %}
          Erreicht
        {% elif current <= 100 %}
          Lädt gerade nicht
        {% elif power <= 100 %}
          Prognose sammelt Daten
        {% else %}
          {% set minutes = (${toString batteryCapacityKWh} * 1000 * (${toString target} - level) / 100 / power * 60) | round(0, 'ceil') | int %}
          {% if minutes > 720 %}
            Über 12 Stunden
          {% else %}
            ca. {{ minutes }} min · {{ (as_timestamp(now()) + minutes * 60) | timestamp_custom('%H:%M') }} Uhr
          {% endif %}
        {% endif %}
      '';
      attributes = {
        battery_capacity_kwh = batteryCapacityKWh;
        basis = "Mittlere Netto-Ladeleistung der letzten 15 Minuten; keine Wetterprognose. Ladung kann nahe 100 % langsamer werden.";
      };
    };
in
{
  environment.etc = {
    "home-assistant/dashboard-waermepumpe.yaml".source = yaml.generate "dashboard-waermepumpe.yaml" (
      import ./dashboards/waermepumpe.nix
    );
    "home-assistant/dashboard-zuhause.yaml".source = yaml.generate "dashboard-zuhause.yaml" (
      import ./dashboards/zuhause.nix
    );
  };

  services.home-assistant.config = {
    lovelace.dashboards = {
      waermepumpe-uebersicht = {
        mode = "yaml";
        filename = "dashboard-waermepumpe.yaml";
        title = "Wärmepumpe";
        icon = "mdi:heat-pump-outline";
        show_in_sidebar = true;
      };
      zuhause-energie = {
        mode = "yaml";
        filename = "dashboard-zuhause.yaml";
        title = "Zuhause";
        icon = "mdi:home-heart";
        show_in_sidebar = true;
      };
    };

    sensor = [
      {
        platform = "statistics";
        name = "Haus Batterie Nettoleistung Mittel";
        unique_id = "haus_batterie_nettoleistung_mittel";
        entity_id = "sensor.haus_batterie_nettoleistung";
        state_characteristic = "average_step";
        max_age.minutes = 15;
        sampling_size = 100;
        precision = 0;
        # Stable power need not change state during the window. The separate
        # freshness check still prevents forecasts from using stale source data.
        keep_last_sample = true;
      }
    ];

    template = [
      {
        binary_sensor = [
          {
            name = "Haus Energiedaten aktuell";
            unique_id = "haus_energiedaten_aktuell";
            default_entity_id = "binary_sensor.haus_energiedaten_aktuell";
            state = freshData;
          }
          {
            name = "Haus guter Zeitpunkt fuer Geraete";
            unique_id = "haus_geraetezeit_gut";
            default_entity_id = "binary_sensor.haus_geraetezeit_gut";
            icon = "mdi:washing-machine";
            state = ''
              {{ is_state('binary_sensor.haus_energiedaten_aktuell', 'on')
                 and states('${soc}') | float(0) >= 90
                 and states('${gridExport}') | float(0) >= ${toString exportThresholdW}
                 and states('${gridImport}') | float(0) < 100
                 and states('${discharge}') | float(0) < 100 }}
            '';
            delay_on = "00:05:00";
            delay_off = "00:00:00";
          }
        ];
        sensor = [
          (sensor "haus_batterie_nettoleistung" "Haus Batterie Nettoleistung" {
            device_class = "power";
            state_class = "measurement";
            unit_of_measurement = "W";
            availability = "{{ is_state('binary_sensor.haus_energiedaten_aktuell', 'on') }}";
            state = "{{ (states('${charge}') | float(0) - states('${discharge}') | float(0)) | round(0) }}";
          })
          (sensor "haus_batterie_prognose_30_min" "Haus Batterie Prognose 30 Minuten" {
            unit_of_measurement = "%";
            icon = "mdi:battery-clock";
            availability = "{{ is_state('binary_sensor.haus_energiedaten_aktuell', 'on') and is_number(states('${meanPower}')) }}";
            state = ''
              {% set level = states('${soc}') | float(0) %}
              {% set current = states('${charge}') | float(0) - states('${discharge}') | float(0) %}
              {% set average = states('${meanPower}') | float(0) %}
              {% set power = average if current * average > 0 else 0 %}
              {{ [[level + power * 0.5 / (${toString batteryCapacityKWh} * 1000) * 100, 0] | max, 100] | min | round(0) }}
            '';
          })
          (timeToTarget 90 "haus_batterie_bis_90" "Haus Batterie bis 90 Prozent")
          (timeToTarget 100 "haus_batterie_bis_voll" "Haus Batterie bis voll")
          (sensor "haus_geraeteempfehlung" "Haus Geräteempfehlung" {
            icon = "mdi:washing-machine";
            state = ''
              {% if not is_state('binary_sensor.haus_energiedaten_aktuell', 'on') %}
                Daten prüfen
              {% elif is_state('binary_sensor.haus_geraetezeit_gut', 'on') %}
                Jetzt starten
              {% elif states('${gridImport}') | float(0) >= 100 %}
                Lieber warten
              {% elif states('${soc}') | float(0) < 90 %}
                Batterie zuerst laden
              {% elif states('${gridExport}') | float(0) >= ${toString exportThresholdW} and states('${discharge}') | float(0) < 100 %}
                Überschuss wird geprüft
              {% else %}
                Wenig Überschuss
              {% endif %}
            '';
            attributes = {
              appliance_power_w = appliancePowerW;
              export_margin_w = exportMarginW;
              minimum_battery_percent = 90;
              required_duration_minutes = 5;
            };
          })
          (sensor "haus_waermepumpe_status" "Haus Wärmepumpe Status" {
            icon = "mdi:heat-pump-outline";
            availability = "{{ is_number(states('${wp}inv_frequency_rps')) and has_value('${wpBinary}defrost_operation') and has_value('${wpBinary}3way_valve_on_dhw_off_space') }}";
            state = ''
              {% if is_state('${wpBinary}defrost_operation', 'on') %}
                Abtauen
              {% elif states('${wp}inv_frequency_rps') | float(0) <= 0 %}
                Bereit / Pause
              {% elif is_state('${wpBinary}3way_valve_on_dhw_off_space', 'on') %}
                Warmwasser
              {% else %}
                Heizbetrieb
              {% endif %}
            '';
          })
          (sensor "haus_heizung_spreizung" "Haus Heizung Spreizung" {
            device_class = "temperature";
            state_class = "measurement";
            unit_of_measurement = "°C";
            availability = "{{ is_number(states('${wp}leaving_water_temp_after_buh_r2t')) and is_number(states('${wp}inlet_water_temp_r4t')) }}";
            state = "{{ (states('${wp}leaving_water_temp_after_buh_r2t') | float(0) - states('${wp}inlet_water_temp_r4t') | float(0)) | round(1) }}";
          })
        ];
      }
    ];
  };
}
