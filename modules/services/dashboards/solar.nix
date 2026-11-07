let
  tile = entity: name: icon: color: {
    type = "tile";
    inherit entity name icon color;
    tap_action.action = "more-info";
  };
  heading = title: icon: {
    type = "heading";
    heading = title;
    heading_style = "title";
    inherit icon;
  };
  arraySection = { title, model, orientation, icon, color, power, energy, powerName ? "Solarleistung (AC)" }: {
    type = "grid";
    cards = [
      (heading title icon)
      {
        type = "markdown";
        content = "**${orientation}** · ${model}";
        text_only = true;
      }
      (tile power powerName "mdi:solar-power" color)
      (tile energy "Ertrag heute" "mdi:solar-power-variant" color)
    ];
  };
in
{
  title = "Solar";
  views = [{
    title = "Übersicht";
    path = "uebersicht";
    type = "sections";
    max_columns = 3;
    header = {
      layout = "responsive";
      badges_position = "bottom";
      card = {
        type = "markdown";
        text_only = true;
        content = "# Solar am Haus\nDrei Anlagen, ein Überblick.";
      };
    };
    sections = [
      {
        type = "grid";
        column_span = 3;
        cards = [
          (heading "Gesamterzeugung" "mdi:solar-power-variant-outline")
          ((tile "sensor.solar_pv_leistung_gesamt" "Solarleistung gesamt" "mdi:white-balance-sunny" "amber") // { grid_options.columns = 12; })
          ((tile "sensor.solar_ertrag_heute_gesamt" "Ertrag heute gesamt" "mdi:solar-power" "orange") // { grid_options.columns = 12; })
          ((tile "sensor.solar_ertrag_gesamt" "Ertrag seit Inbetriebnahme" "mdi:counter" "teal") // { grid_options.columns = 12; })
        ];
      }
      (arraySection {
        title = "Straße vorne";
        model = "SPH 10000TL3 BH-UP";
        orientation = "Osten";
        icon = "mdi:weather-sunset-up";
        color = "amber";
        power = "sensor.__growatt_sph_id___pv_gesamtleistung";
        powerName = "PV-Leistung";
        energy = "sensor.__growatt_sph_id___pv_energie_heute";
      })
      (arraySection {
        title = "Garten";
        model = "MID 17KTL3-X";
        orientation = "Westen";
        icon = "mdi:weather-sunset-down";
        color = "teal";
        power = "sensor.garten_total_ausgangsleistung";
        energy = "sensor.garten_total_energie_heute";
      })
      (arraySection {
        title = "Balkonkraftwerk";
        model = "9000 TL3-S";
        orientation = "Westen / Süden";
        icon = "mdi:balcony";
        color = "orange";
        power = "sensor.balkonkraftwerk_total_ausgangsleistung";
        energy = "sensor.balkonkraftwerk_total_energie_heute";
      })
      {
        type = "grid";
        column_span = 2;
        cards = [
          (heading "Batteriespeicher · Straße vorne" "mdi:battery-high")
          {
            type = "gauge";
            entity = "sensor.__growatt_sph_id___ladezustand";
            name = "Ladezustand";
            min = 0;
            max = 100;
            needle = true;
            severity = { red = 0; yellow = 20; green = 50; };
          }
          (tile "sensor.__growatt_sph_id___batterieaufladung" "Ladeleistung" "mdi:battery-arrow-up" "green")
          (tile "sensor.__growatt_sph_id___batterieentladung_w" "Entladeleistung" "mdi:battery-arrow-down" "orange")
          (tile "sensor.__growatt_sph_id___batterieaufladung_heute" "Heute geladen" "mdi:battery-plus" "green")
          (tile "sensor.__growatt_sph_id___batterieentladung_heute" "Heute entladen" "mdi:battery-minus" "orange")
          {
            type = "history-graph";
            title = "Ladezustand · 24 Stunden";
            hours_to_show = 24;
            entities = [{ entity = "sensor.__growatt_sph_id___ladezustand"; name = "Batterie"; }];
            grid_options.columns = "full";
          }
        ];
      }
      {
        type = "grid";
        cards = [
          (heading "Netz · Straße vorne" "mdi:transmission-tower")
          (tile "sensor.__growatt_sph_id___netzbezug" "Netzbezug" "mdi:transmission-tower-import" "red")
          (tile "sensor.__growatt_sph_id___netzeinspeisung" "Einspeisung" "mdi:transmission-tower-export" "green")
          (tile "sensor.__growatt_sph_id___netzbezug_heute_last" "Netzbezug heute" "mdi:home-import-outline" "red")
          (tile "sensor.__growatt_sph_id___netzeinspeisung_heute" "Einspeisung heute" "mdi:home-export-outline" "green")
          {
            type = "markdown";
            text_only = true;
            content = "Netzwerte vom Messpunkt des SPH. Growatt aktualisiert die Cloud-Daten ungefähr alle fünf Minuten.";
          }
        ];
      }
      {
        type = "grid";
        column_span = 3;
        cards = [{
          type = "history-graph";
          title = "Ost und West im Vergleich · 24 Stunden";
          hours_to_show = 24;
          entities = [
            { entity = "sensor.__growatt_sph_id___pv_gesamtleistung"; name = "Straße vorne · Ost"; }
            { entity = "sensor.garten_total_ausgangsleistung"; name = "Garten · West"; }
            { entity = "sensor.balkonkraftwerk_total_ausgangsleistung"; name = "Balkonkraftwerk · West/Süd"; }
          ];
          grid_options = { columns = "full"; };
        }];
      }
    ];
  }];
}
