{ ... }:

let
  # Use the SPH's PV readings, since its AC output can include discharge.
  # For the two non-hybrid systems, plant totals work while several detailed
  # inverter readings incorrectly return zero. Do not add both device and
  # plant totals: each plant contains one inverter.
  # Power combines DC PV input at the SPH with AC output at the other plants;
  # it is an overview of generation, not a meter for an exact energy balance.
  pvPower = [
    "sensor.__growatt_sph_id___pv_gesamtleistung"
    "sensor.garten_total_ausgangsleistung"
    "sensor.balkonkraftwerk_total_ausgangsleistung"
  ];
  energyToday = [
    "sensor.__growatt_sph_id___pv_energie_heute"
    "sensor.garten_total_energie_heute"
    "sensor.balkonkraftwerk_total_energie_heute"
  ];
  energyLifetime = [
    "sensor.__growatt_sph_id___pv_energie_uber_lebensdauer"
    "sensor.garten_total_energieabgabe_uber_lebensdauer"
    "sensor.balkonkraftwerk_total_energieabgabe_uber_lebensdauer"
  ];
  # Keep energy totals unavailable when data is missing to avoid false resets
  # in statistics. Instantaneous power can count offline inverters as zero.
  sumSensor =
    {
      id,
      name,
      sources,
      unit,
      deviceClass,
      stateClass,
      precision,
      allowMissing ? false,
    }:
    {
      inherit name;
      unique_id = id;
      default_entity_id = "sensor.${id}";
      unit_of_measurement = unit;
      device_class = deviceClass;
      state_class = stateClass;
      availability =
        if allowMissing then
          "{{ true }}"
        else
          "{{ [${builtins.concatStringsSep ", " (map (e: "is_number(states('${e}'))") sources)}] | min }}";
      state = "{{ (${
        builtins.concatStringsSep " + " (map (e: "states('${e}') | float(0)") sources)
      }) | round(${toString precision}) }}";
    };
in
{
  services.home-assistant = {
    lovelaceConfig = import ./dashboards/solar.nix;

    config = {
      # An additional YAML dashboard; UI-managed dashboards, including Daikin,
      # continue to be managed through Home Assistant's normal storage mode.
      lovelace.dashboards.nixos-lovelace = {
        mode = "yaml";
        filename = "ui-lovelace.yaml";
        title = "Solar";
        icon = "mdi:solar-power";
        show_in_sidebar = true;
      };

      template = [
        {
          sensor = [
            (sumSensor {
              id = "solar_pv_leistung_gesamt";
              name = "Solarleistung gesamt";
              sources = pvPower;
              allowMissing = true;
              unit = "W";
              deviceClass = "power";
              stateClass = "measurement";
              precision = 0;
            })
            (sumSensor {
              id = "solar_ertrag_heute_gesamt";
              name = "Solar Ertrag heute gesamt";
              sources = energyToday;
              unit = "kWh";
              deviceClass = "energy";
              stateClass = "total_increasing";
              precision = 2;
            })
            (sumSensor {
              id = "solar_ertrag_gesamt";
              name = "Solar Ertrag gesamt";
              sources = energyLifetime;
              unit = "kWh";
              deviceClass = "energy";
              stateClass = "total";
              precision = 2;
            })
          ];
        }
      ];
    };
  };
}
