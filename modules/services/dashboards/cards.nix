{
  reading = entity: name: icon: {
    type = "sensor";
    inherit entity name icon;
    grid_options.columns = 12;
  };
  tile = entity: name: icon: color: {
    type = "tile";
    inherit
      entity
      name
      icon
      color
      ;
    grid_options.columns = 12;
    tap_action.action = "more-info";
  };
  heading = title: icon: {
    type = "heading";
    heading = title;
    heading_style = "title";
    inherit icon;
    grid_options.columns = "full";
  };
  history = title: entities: {
    type = "history-graph";
    inherit title entities;
    hours_to_show = 24;
    grid_options.columns = "full";
  };
  header = title: subtitle: {
    layout = "responsive";
    card = {
      type = "markdown";
      text_only = true;
      content = "# ${title}\n${subtitle}";
    };
  };
}
