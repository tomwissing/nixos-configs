let
  inherit (import ./cards.nix) tile reading heading header;
  s = "sensor.esphome_altherma___altherma_id___";
  notice = state: content: {
    type = "conditional";
    conditions = [{ condition = "state"; entity = "sensor.haus_geraeteempfehlung"; inherit state; }];
    card = { type = "markdown"; inherit content; };
    grid_options.columns = "full";
  };
in
{
  title = "Zuhause";
  views = [{
    title = "Zuhause";
    path = "jetzt";
    type = "sections";
    max_columns = 2;
    header = header "Strom im Blick" "Was ist jetzt ein guter Zeitpunkt?";
    sections = [
      {
        type = "grid";
        column_span = 2;
        cards = [
          (notice "Jetzt starten" ''
            # ☀️ Jetzt passt es gut
            Die Batterie ist mindestens **90 %** geladen und es geht seit fünf Minuten genug Strom ins Netz.

            **Ein großes Gerät kann jetzt starten**, zum Beispiel Waschmaschine oder Spülmaschine.
          '')
          (notice "Batterie zuerst laden" ''
            # 🔋 Erst die Batterie laden lassen
            Wenn es nicht eilig ist, mit der Wäsche noch warten, bis die Batterie **90 %** erreicht hat.

            Die geschätzte Ladezeit steht unten.
          '')
          (notice "Lieber warten" ''
            # ⏳ Lieber noch warten
            Das Haus bezieht gerade Strom aus dem Netz. Ein zusätzliches großes Gerät würde den Netzbezug erhöhen.
          '')
          (notice "Überschuss wird geprüft" ''
            # 🌤️ Sieht gut aus – kurz abwarten
            Es ist genug Überschuss da. Wenn das fünf Minuten so bleibt, erscheint hier **„Jetzt passt es gut“**.
          '')
          (notice "Wenig Überschuss" ''
            # 🌥️ Noch wenig Strom übrig
            Die Batterie ist gut gefüllt, aber für ein zusätzliches großes Gerät wird gerade nicht genug Strom eingespeist.
          '')
          (notice "Daten prüfen" ''
            # 🕒 Auf aktuelle Werte warten
            Die Energiedaten fehlen oder sind zu alt. Im Moment lässt sich kein guter Startzeitpunkt empfehlen.
          '')
        ];
      }
      {
        type = "grid";
        cards = [
          (heading "Strom gerade" "mdi:home-lightning-bolt-outline")
          (reading "sensor.__growatt_sph_id___netzeinspeisung" "Strom übrig · ins Netz" "mdi:transmission-tower-export")
          (reading "sensor.__growatt_sph_id___netzbezug" "Strom aus dem Netz" "mdi:transmission-tower-import")
          (tile "sensor.solar_pv_leistung_gesamt" "Sonne · alle Anlagen" "mdi:white-balance-sunny" "amber")
          {
            type = "markdown";
            text_only = true;
            content = "**Mehr Einspeisung ist gut für zusätzliche Geräte.** Ein großes Gerät nach dem anderen starten. Die Anzeige beurteilt den Moment, nicht den ganzen Waschgang.";
          }
        ];
      }
      {
        type = "grid";
        cards = [
          (heading "Batterie" "mdi:battery-heart-variant")
          {
            type = "gauge";
            entity = "sensor.__growatt_sph_id___ladezustand";
            name = "So voll ist die Batterie";
            min = 0;
            max = 100;
            needle = true;
            severity = { red = 0; yellow = 30; green = 90; };
            grid_options.columns = "full";
          }
          (tile "sensor.__growatt_sph_id___batterieaufladung" "Batterie lädt mit" "mdi:battery-arrow-up" "green")
          (tile "sensor.__growatt_sph_id___batterieentladung_w" "Batterie versorgt das Haus mit" "mdi:battery-arrow-down" "orange")
        ];
      }
      {
        type = "grid";
        cards = [
          (heading "Wann ist die Batterie voll?" "mdi:battery-clock-outline")
          (tile "sensor.haus_batterie_bis_90" "Bis 90 % · geschätzt" "mdi:battery-90" "teal")
          (tile "sensor.haus_batterie_bis_voll" "Bis voll · grob geschätzt" "mdi:battery" "green")
          (tile "sensor.haus_batterie_prognose_30_min" "In 30 Minuten · geschätzt" "mdi:clock-outline" "blue")
          {
            type = "markdown";
            text_only = true;
            content = "Mit **12,5 kWh** und dem Ladeverlauf der letzten 15 Minuten gerechnet. Das gilt bei ähnlicher Sonne und ähnlichem Verbrauch. Nahe 100 % kann das Laden langsamer werden.";
          }
        ];
      }
      {
        type = "grid";
        cards = [
          (heading "Heizung & warmes Wasser" "mdi:heat-pump-outline")
          (tile "sensor.haus_waermepumpe_status" "Die Wärmepumpe" "mdi:heat-pump" "teal")
          (tile "${s}altherma_estimated_power" "Strombedarf · geschätzt" "mdi:lightning-bolt" "amber")
          (tile "${s}dhw_tank_temp_r5t" "Warmes Wasser" "mdi:water-thermometer" "orange")
          (tile "${s}outdoor_air_temp_r1t" "Temperatur draußen" "mdi:thermometer" "blue")
          {
            type = "button";
            name = "Mehr zur Wärmepumpe";
            icon = "mdi:heat-pump-outline";
            tap_action = { action = "navigate"; navigation_path = "/waermepumpe-uebersicht/uebersicht"; };
            grid_options.columns = "full";
          }
        ];
      }
      {
        type = "grid";
        column_span = 2;
        cards = [
          (tile "sensor.__growatt_sph_id___letzte_datenaktualisierung" "Letzter Growatt-Messwert" "mdi:clock-check-outline" "blue")
          {
            type = "markdown";
            text_only = true;
            content = ''
              **So wird „Jetzt starten“ entschieden:** Batterie mindestens 90 %, mindestens 2.300 W Einspeisung seit fünf Minuten, weniger als 100 W Netzbezug und keine nennenswerte Batterieentladung. Das ist für ungefähr **ein 2.000-W-Gerät** gedacht.

              Growatt liefert Cloud-Werte ungefähr alle fünf Minuten. Die Wärmepumpe wird hier nur angezeigt und weiterhin normal geregelt.
            '';
            grid_options.columns = "full";
          }
        ];
      }
    ];
  }];
}
