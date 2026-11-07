let
  inherit (import ./cards.nix) tile heading history header;
  s = "sensor.esphome_altherma___altherma_id___";
  b = "binary_sensor.esphome_altherma___altherma_id___";
in
{
  title = "Wärmepumpe";
  views = [
    {
      title = "Übersicht";
      path = "uebersicht";
      type = "sections";
      max_columns = 3;
      header = header "Wärme im Blick" "Daikin Altherma · Heizung und Warmwasser";
      sections = [
        {
          type = "grid";
          column_span = 3;
          cards = [
            (heading "So läuft die Wärmepumpe" "mdi:heat-pump-outline")
            (tile "sensor.haus_waermepumpe_status" "Betrieb" "mdi:heat-pump" "teal")
            (tile "${s}altherma_estimated_power" "Elektrische Leistung · geschätzt" "mdi:lightning-bolt" "amber")
            (tile "${s}outdoor_air_temp_r1t" "Draußen" "mdi:thermometer" "blue")
          ];
        }
        {
          type = "grid";
          cards = [
            (heading "Heizkreis" "mdi:radiator")
            (tile "${s}leaving_water_temp_after_buh_r2t" "Vorlauf" "mdi:thermometer-chevron-up" "orange")
            (tile "${s}inlet_water_temp_r4t" "Rücklauf" "mdi:thermometer-chevron-down" "blue")
            (tile "${s}lw_setpoint_main" "Heizwasser · Soll" "mdi:thermometer-check" "teal")
            (tile "sensor.haus_heizung_spreizung" "Vorlauf minus Rücklauf" "mdi:delta" "purple")
          ];
        }
        {
          type = "grid";
          cards = [
            (heading "Warmwasser" "mdi:water-boiler")
            (tile "${s}dhw_tank_temp_r5t" "Speichertemperatur" "mdi:water-thermometer" "orange")
            (tile "${s}dhw_setpoint" "Warmwasser · Soll" "mdi:thermometer-check" "teal")
            (tile "${b}3way_valve_on_dhw_off_space" "Warmwasserventil aktiv" "mdi:valve" "blue")
          ];
        }
        {
          type = "grid";
          cards = [
            (heading "Raum & Wärmeverteilung" "mdi:home-thermometer-outline")
            (tile "${s}indoor_ambient_temp_r1t" "Innenfühler" "mdi:home-thermometer" "teal")
            (tile "${s}flow_sensor_l_min" "Wasserdurchfluss" "mdi:waves-arrow-right" "blue")
            (tile "${s}water_pressure_bar" "Wasserdruck" "mdi:gauge" "blue")
            (tile "${b}defrost_operation" "Abtauen aktiv" "mdi:snowflake-melt" "cyan")
          ];
        }
        {
          type = "grid";
          column_span = 2;
          cards = [
            (history "Heizwasser · 24 Stunden" [
              { entity = "${s}leaving_water_temp_after_buh_r2t"; name = "Vorlauf"; }
              { entity = "${s}inlet_water_temp_r4t"; name = "Rücklauf"; }
              { entity = "${s}lw_setpoint_main"; name = "Soll"; }
            ])
          ];
        }
        {
          type = "grid";
          cards = [
            (history "Warmwasser · 24 Stunden" [
              { entity = "${s}dhw_tank_temp_r5t"; name = "Speicher"; }
              { entity = "${s}dhw_setpoint"; name = "Soll"; }
            ])
          ];
        }
      ];
    }
    {
      title = "Technik";
      path = "technik";
      icon = "mdi:tools";
      type = "sections";
      max_columns = 3;
      header = header "Technik & Verlauf" "Messwerte zum Nachsehen, ohne Heizungssteuerung.";
      sections = [
        {
          type = "grid";
          cards = [
            (heading "Antrieb" "mdi:engine-outline")
            (tile "${s}inv_frequency_rps" "Verdichterfrequenz" "mdi:sine-wave" "purple")
            (tile "${s}fan_1_10_rpm" "Lüfterdrehzahl" "mdi:fan" "teal")
            {
              type = "entities";
              title = "Pumpe & Kältekreis";
              show_header_toggle = false;
              entities = [
                { entity = "${s}water_pump_signal_0_max_100_stop"; name = "Pumpensignal · 0=max, 100=Stopp"; }
                { entity = "${s}refrig_temp_liquid_side_r3t"; name = "Kältemittel · Flüssigkeitsseite"; }
              ];
            }
          ];
        }
        {
          type = "grid";
          cards = [{
            type = "entities";
            title = "Betrieb & Schutzfunktionen";
            show_header_toggle = false;
            entities = [
              { entity = "${b}thermostat_on_off"; name = "Heizanforderung"; }
              { entity = "${b}defrost_operation"; name = "Abtauen"; }
              { entity = "${b}freeze_protection"; name = "Frostschutz"; }
              { entity = "${b}silent_mode"; name = "Leisemodus"; }
              { entity = "${b}buh_step1"; name = "Zusatzheizung · Stufe 1"; }
              { entity = "${b}buh_step2"; name = "Zusatzheizung · Stufe 2"; }
              { entity = "${b}bsh"; name = "Warmwasser-Zusatzheizung"; }
            ];
          }];
        }
        {
          type = "grid";
          cards = [{
            type = "entities";
            title = "Diagnose";
            show_header_toggle = false;
            entities = [
              { entity = "${s}i_u_operation_mode"; name = "Betriebsmodus · Rohwert"; }
              { entity = "${s}error_code"; name = "Fehlercode"; }
              { entity = "${s}error_detailed_code"; name = "Fehlerdetail"; }
              { entity = "${s}error_type"; name = "Fehlertyp"; }
            ];
          }];
        }
        {
          type = "grid";
          column_span = 3;
          cards = [
            (history "Elektrische Leistung · geschätzt" [{ entity = "${s}altherma_estimated_power"; name = "Leistung"; }])
            (history "Verdichterfrequenz" [{ entity = "${s}inv_frequency_rps"; name = "Verdichter"; }])
          ];
        }
      ];
    }
  ];
}
