H2O.PartialDependenceOutput = (_, _go, _result) ->

  _destinationKey = _result.destination_key
  _modelId = _result.model_id.name
  _frameId = _result.frame_id.name
  _pdpdata = _result.partial_dependence_data

  renderPlot = (target, render) ->
    render (error, vis) ->
      if error
        debug error
      else
        target vis.element

  _partialDependencePlots = map _pdpdata, (item) ->
  	description: item.columns[0].description
  	plot: signal null
  	table: signal null

  for pdp,i in _partialDependencePlots 
    if table = _.inspect 'data', _pdpdata[i].data
      renderPlot pdp.plot, _.plot (g) -> g(
          g.path(
            g.position _pdpdata[i].columns[0].name, _pdpdata[i].columns[1].name
          )
          g.from table
        )

  _viewFrame = ->
    _.insertAndExecuteCell 'cs', "requestPartialDependenceData #{stringify _destinationKey}"

  defer _go

  destinationKey: _destinationKey
  modelId: _modelId
  frameId: _frameId
  partialDependencePlots: _partialDependencePlots
  viewFrame: _viewFrame
  template: 'flow-partial-dependence-output'

