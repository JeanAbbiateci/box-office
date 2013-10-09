
class BubbleChart
  constructor: (data) ->
    @data = data
    @width = 695
    @height = 690

    @tooltip = CustomTooltip("gates_tooltip", 240)

    # locations the nodes will move towards
    # depending on which view is currently being
    # used
    @center = {x: @width / 2, y: @height / 2.4}
    @year_centers = {
      "1A": {x: 1.2 * @width / 4, y: @height / 2.7},
      "2A": {x: 2 * @width / 4, y: @height / 2.9},
      "3A": {x: 2.8 * @width / 4, y: @height / 3.0}
      "4A": {x: 1.2 * @width / 4, y: 2 * @height / 3.3}
      "5A": {x: 2 * @width / 4, y: 2 * @height / 3.2}
      "6A": {x: 2.8 * @width / 3.9, y: 2 * @height / 3.3}
    }
    @pays_centers = {

    "Amerique du Nord": {x: 1*  @width / 3, y: @height / 2.8}
    "Asie": {x: 2.8 * @width / 6, y: 2 * @height / 3.5}
    "France": {x: 4 * @width / 6, y: 1 * @height / 2.8}
    "Amerique du Sud": {x: 3.72*  @width / 5, y: 2 * @height / 3.5}
    "Oceanie": {x: 3.6 * @width / 6, y: 2 * @height / 3.5}
    "Europe": {x: 2 * @width / 7, y: 2 * @height / 3.4}
    }

    @pressesimp_centers = {

    "1": {x: 1*  @width / 3.3, y: @height / 3.3}
    "2": {x: 4 * @width / 6, y: 1 * @height / 2.8}
    "3": {x: 2 * @width / 6, y: 2 * @height / 3.6}
    "4": {x: 3.2*  @width / 5, y: 2 * @height / 3.35}
    "_": {x: 10 * @width / 7, y: 10 * @height / 3}
    }

    @spectsimp_centers = {

    "1": {x: 1*  @width / 3.3, y: @height / 3.3}
    "2": {x: 4 * @width / 6, y: 1 * @height / 2.8}
    "3": {x: 2 * @width / 6, y: 2 * @height / 3.6}
    "4": {x: 3.2*  @width / 5, y: 2 * @height / 3.35}
    "_": {x: 10 * @width / 7, y: 10 * @height / 3}
    }


    # used when setting up force and
    # moving around nodes
    @layout_gravity = -0.01
    @damper = 0.1

    # these will be set in create_nodes and create_vis
    @vis = null
    @nodes = []
    @force = null
    @circles = null

    # nice looking colors - no reason to buck the trend
    @fill_color = d3.scale.ordinal()
      .domain(["1", "2", "3", "4", "5"])
      .range(["#FFF7BC", "#FEC44F", "#D95F0E","#a50000", "#F0F0F0"])

    # use the max total_amount in the data as the max in the scale's domain
    max_amount = d3.max(@data, (d) -> parseInt(d.total_amount))
    @radius_scale = d3.scale.pow().exponent(0.5).domain([0, max_amount]).range([2, 55])
    
    this.create_nodes()
    this.create_vis()

  # create node objects from original data
  # that will serve as the data behind each
  # bubble in the vis, then add each node
  # to @nodes to be used later
  create_nodes: () =>
    @data.forEach (d) =>
      node = {
        id: d.id
        radius: @radius_scale(parseInt(d.total_amount))
        value: d.total_amount
        name: d.grant_title
        org: d.organization
        group: d.group
        year: d.start_year
        pays: d.pays
        pays1: d.pays1
        real: d.real
        presse: d.presse
        pressesimp: d.pressesimp
        spect: d.spect
        spectsimp: d.spectsimp
        x: Math.random() * 900
        y: Math.random() * 800
      }
      @nodes.push node

    @nodes.sort (a,b) -> b.value - a.value


  # create svg at #vis and then 
  # create circle representation for each node
  create_vis: () =>
    @vis = d3.select("#vis").append("svg")
      .attr("width", @width)
      .attr("height", @height)
      .attr("id", "svg_vis")

    @circles = @vis.selectAll("circle")
      .data(@nodes, (d) -> d.id)

    # used because we need 'this' in the 
    # mouse callbacks
    that = this

    # radius will be set to 0 initially.
    # see transition below
    @circles.enter().append("circle")
      .attr("r", 0)
      .attr("fill", (d) => @fill_color(d.group))
      .attr("stroke-width", 1.5)
      .attr("stroke", (d) => d3.rgb(@fill_color(d.group)).darker())
      .attr("id", (d) -> "bubble_#{d.id}")
      .on("mouseover", (d,i) -> that.show_details(d,i,this))
      .on("mouseout", (d,i) -> that.hide_details(d,i,this))

    # Fancy transition to make bubbles appear, ending with the
    # correct radius
    @circles.transition().duration(2000).attr("r", (d) -> d.radius)


  # Charge function that is called for each node.
  # Charge is proportional to the diameter of the
  # circle (which is stored in the radius attribute
  # of the circle's associated data.
  # This is done to allow for accurate collision 
  # detection with nodes of different sizes.
  # Charge is negative because we want nodes to 
  # repel.
  # Dividing by 8 scales down the charge to be
  # appropriate for the visualization dimensions.
  charge: (d) ->
    -Math.pow(d.radius, 2.0) / 8

  # Starts up the force layout with
  # the default values
  start: () =>
    @force = d3.layout.force()
      .nodes(@nodes)
      .size([@width, @height])

  # Sets up force layout to display
  # all nodes in one circle.
  display_group_all: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @circles.each(this.move_towards_center(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
    @force.start()

    this.hide_years()
    this.hide_payss()
    this.hide_pressesimps()
    this.hide_spectsimps()


  # Moves all circles towards the @center
  # of the visualization
  move_towards_center: (alpha) =>
    (d) =>
      d.x = d.x + (@center.x - d.x) * (@damper + 0.02) * alpha
      d.y = d.y + (@center.y - d.y) * (@damper + 0.02) * alpha


  # sets the display of bubbles to be separated
  # into each year. Does this by calling move_towards_year
  display_by_year: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @circles.each(this.move_towards_year(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
    @force.start()

    this.hide_payss()
    this.hide_pressesimps()
    this.hide_spectsimps()
    this.display_years()


  # sets the display of bubbles to be separated
  # into each pays. Does this by calling move_towards_pays
  display_by_pays: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @circles.each(this.move_towards_pays(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
    @force.start()

    this.hide_years()
    this.hide_pressesimps()
    this.hide_spectsimps()
    this.display_payss()

  # sets the display of bubbles to be separated
  # into each pressesimp. Does this by calling move_towards_pressesimp
  display_by_pressesimp: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @circles.each(this.move_towards_pressesimp(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
    @force.start()

    this.hide_years()
    this.hide_payss()
    this.hide_spectsimps()
    this.display_pressesimps()

  # sets the display of bubbles to be separated
  # into each spectsimp. Does this by calling move_towards_spectsimp
  display_by_spectsimp: () =>
    @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
        @circles.each(this.move_towards_spectsimp(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
    @force.start()

    this.hide_years()
    this.hide_payss()
    this.hide_pressesimps()
    this.display_spectsimps()

  # move all circles to their associated @year_centers 
  move_towards_year: (alpha) =>
    (d) =>
      target = @year_centers[d.year]
      d.x = d.x + (target.x - d.x) * (@damper + 0.02) * alpha * 1.1
      d.y = d.y + (target.y - d.y) * (@damper + 0.02) * alpha * 1.1

  # move all circles to their associated @pays_centers 
  move_towards_pays: (alpha) =>
    (d) =>
      target = @pays_centers[d.pays]
      d.x = d.x + (target.x - d.x) * (@damper + 0.02) * alpha * 1.1
      d.y = d.y + (target.y - d.y) * (@damper + 0.02) * alpha * 1.1
	 
  # move all circles to their associated @pressesimp_centers 
  move_towards_pressesimp: (alpha) =>
    (d) =>
      target = @pressesimp_centers[d.pressesimp]
      d.x = d.x + (target.x - d.x) * (@damper + 0.02) * alpha * 1.1
      d.y = d.y + (target.y - d.y) * (@damper + 0.02) * alpha * 1.1
	 
  # move all circles to their associated @spectsimp_centers 
  move_towards_spectsimp: (alpha) =>
    (d) =>
      target = @spectsimp_centers[d.spectsimp]
      d.x = d.x + (target.x - d.x) * (@damper + 0.02) * alpha * 1.1
      d.y = d.y + (target.y - d.y) * (@damper + 0.02) * alpha * 1.1


  # Method to display year titles
  display_years: () =>
    years_x = {"Comédie - Romance": 160, "Drame": 375, "Action - Aventure - Thriller": 570,"Animations - Comics": 160, "Fantasy - SF - Horreur": 395, "Documentaire": 595}
    years_y = {"Comédie - Romance": 50, "Drame": 50, "Action - Aventure - Thriller": 50,"Animations - Comics": 390, "Fantasy - SF - Horreur": 390, "Documentaire": 390,}
    years_data = d3.keys(years_x)
    years = @vis.selectAll(".years")
      .data(years_data)

    years.enter().append("text")
      .attr("class", "years")
      .attr("x", (d) => years_x[d] )
      .attr("y", (d) => years_y[d] )
      .attr("text-anchor", "middle")
      .text((d) -> d)
	  
	  
  # Method to display pays titles
  display_payss: () =>
    payss_x = {"Amérique du Nord": 200, "France": 515,"Europe (hors France)": 160, "Asie": 340, "Océanie": 460, "Amérique du Sud": 600}
    payss_y = {"Amérique du Nord": 50, "France": 50,"Europe (hors France)": 445, "Asie": 445, "Océanie": 445, "Amérique du Sud": 445}
    payss_data = d3.keys(payss_x)
    payss = @vis.selectAll(".payss")
      .data(payss_data)

    payss.enter().append("text")
      .attr("class", "payss")
      .attr("x", (d) => payss_x[d] )
      .attr("y", (d) => payss_y[d] )
      .attr("text-anchor", "middle")
      .text((d) -> d)

  # Method to display pressesimp titles
  display_pressesimps: () =>
    pressesimps_x = {"Moins de 2 étoiles": 150, "Entre 2 et 3 étoiles": 485, "Entre 3 et 4 étoiles": 150,"Plus de 4 étoiles": 490, "Non noté": 395}
    pressesimps_y = {"Moins de 2 étoiles": 50, "Entre 2 et 3 étoiles": 50, "Entre 3 et 4 étoiles": 230,"Plus de 4 étoiles": 380, "Non noté": 780}
    pressesimps_data = d3.keys(pressesimps_x)
    pressesimps = @vis.selectAll(".pressesimps")
      .data(pressesimps_data)

    pressesimps.enter().append("text")
      .attr("class", "pressesimps")
      .attr("x", (d) => pressesimps_x[d] )
      .attr("y", (d) => pressesimps_y[d] )
      .attr("text-anchor", "middle")
      .text((d) -> d)

  # Method to display spectsimp titles
  display_spectsimps: () =>
    spectsimps_x = {"Moins de 2 étoiles": 150, "Entre 2 et 3 étoiles": 485, "Entre 3 et 4 étoiles": 150,"Plus de 4 étoiles": 490, "Non noté": 395}
    spectsimps_y = {"Moins de 2 étoiles": 50, "Entre 2 et 3 étoiles": 50, "Entre 3 et 4 étoiles": 180,"Plus de 4 étoiles": 330, "Non noté": 780}
    spectsimps_data = d3.keys(spectsimps_x)
    spectsimps = @vis.selectAll(".spectsimps")
      .data(spectsimps_data)

    spectsimps.enter().append("text")
      .attr("class", "spectsimps")
      .attr("x", (d) => spectsimps_x[d] )
      .attr("y", (d) => spectsimps_y[d] )
      .attr("text-anchor", "middle")
      .text((d) -> d)

  

  # Method to hide year titiles
  hide_years: () =>
    years = @vis.selectAll(".years").remove()

  show_details: (data, i, element) =>
    d3.select(element).attr("stroke", "black")
    content = "<span class=\"name\"></span><span class=\"value\"><big> #{data.name}</big></span><br><small> #{data.real} - #{data.pays1} </small><br><hr>"
    content +="<span class=\"name\"></span><span class=\"value\"> #{addCommas(data.value)} entrées</span><br/><hr>"
    content +="<span class=\"name\"></span><span class=\"value\"><small>Note presse :  #{(data.e)} / 5</small></span><br/>"
    content +="<span class=\"name\"></span><span class=\"value\"><small>Note spectateurs :  #{(data.spect)} / 5</small></span><br/>"
    @tooltip.showTooltip(content,d3.event)


  hide_details: (data, i, element) =>
    d3.select(element).attr("stroke", (d) => d3.rgb(@fill_color(d.group)).darker())
    @tooltip.hideTooltip()
	
	
  # Method to hide pays titiles
  hide_payss: () =>
    payss = @vis.selectAll(".payss").remove()

  show_details: (data, i, element) =>
    d3.select(element).attr("stroke", "black")
    content = "<span class=\"name\"></span><span class=\"value\"><big> #{data.name}</big></span><br><small> #{data.real} - #{data.pays1} </small><br><hr>"
    content +="<span class=\"name\"></span><span class=\"value\"> #{addCommas(data.value)} entrées</span><br/><hr>"
    content +="<span class=\"name\"></span><span class=\"value\"><small>Note presse :  #{(data.presse)} / 5</small></span><br/>"
    content +="<span class=\"name\"></span><span class=\"value\"><small>Note spectateurs :  #{(data.spect)} / 5</small></span><br/>"
    @tooltip.showTooltip(content,d3.event)


  hide_details: (data, i, element) =>
    d3.select(element).attr("stroke", (d) => d3.rgb(@fill_color(d.group)).darker())
    @tooltip.hideTooltip()

  # Method to hide pressesimp titiles
  hide_pressesimps: () =>
    pressesimps = @vis.selectAll(".pressesimps").remove()

  show_details: (data, i, element) =>
    d3.select(element).attr("stroke", "black")
    content = "<span class=\"name\"></span><span class=\"value\"><big> #{data.name}</big></span><br><small> #{data.real} - #{data.pays1} </small><br><hr>"
    content +="<span class=\"name\"></span><span class=\"value\"> #{addCommas(data.value)} entrées</span><br/><hr>"
    content +="<span class=\"name\"></span><span class=\"value\"><small>Note presse :  #{(data.presse)} / 5</small></span><br/>"
    content +="<span class=\"name\"></span><span class=\"value\"><small>Note spectateurs :  #{(data.spect)} / 5</small></span><br/>"
    @tooltip.showTooltip(content,d3.event)


  hide_details: (data, i, element) =>
    d3.select(element).attr("stroke", (d) => d3.rgb(@fill_color(d.group)).darker())
    @tooltip.hideTooltip()

  # Method to hide spectsimp titiles
  hide_spectsimps: () =>
    spectsimps = @vis.selectAll(".spectsimps").remove()

  show_details: (data, i, element) =>
    d3.select(element).attr("stroke", "black")
    content = "<span class=\"name\"></span><span class=\"value\"><big> #{data.name}</big></span><br><small> #{data.real} - #{data.pays1} </small><br><hr>"
    content +="<span class=\"name\"></span><span class=\"value\"> #{addCommas(data.value)} entrées</span><br/><hr>"
    content +="<span class=\"name\"></span><span class=\"value\"><small>Note presse :  #{(data.presse)} / 5</small></span><br/>"
    content +="<span class=\"name\"></span><span class=\"value\"><small>Note spectateurs :  #{(data.spect)} / 5</small></span><br/>"
    @tooltip.showTooltip(content,d3.event)


  hide_details: (data, i, element) =>
    d3.select(element).attr("stroke", (d) => d3.rgb(@fill_color(d.group)).darker())
    @tooltip.hideTooltip()


root = exports ? this

$ ->
  chart = null

  render_vis = (csv) ->
    chart = new BubbleChart csv
    chart.start()
    root.display_all()
  root.display_all = () =>
    chart.display_group_all()
  root.display_year = () =>
    chart.display_by_year()
  root.display_pays = () =>
    chart.display_by_pays()
  root.display_pressesimp = () =>
    chart.display_by_pressesimp()
  root.display_spectsimp = () =>
    chart.display_by_spectsimp()

  root.toggle_view = (view_type) =>
    if view_type == 'year'
      root.display_year()
    else if view_type == 'pressesimp'
      root.display_pressesimp()
    else if view_type == 'pays'
      root.display_pays()
    else if view_type == 'spectsimp'
      root.display_spectsimp()
    else
      root.display_all()


  d3.csv "data/datas2011.csv", render_vis
