H2O.Proxy = (_) ->
  doGet = (path, go) ->
    $.getJSON(path)
      .done (data, status, xhr) ->
        go null, data
      .fail (xhr, status, error) ->
        message = if xhr.responseJSON?.errmsg
          xhr.responseJSON.errmsg
        else if status is 0
          'Could not connect to H2O'
        else
          'Unknown error'
        go new Flow.Error message, new Flow.Error "Error calling GET #{path}"

  doPost = (path, opts, go) ->
    $.post(path, opts)
      .done (data, status, xhr) ->
        go null, data
      .fail (xhr, status, error) ->
        message = if xhr.responseJSON?.errmsg
          xhr.responseJSON.errmsg
        else if status is 0
          'Could not connect to H2O'
        else
          'Unknown error'
        go new Flow.Error message, new Flow.Error "Error calling POST #{path} with opts #{JSON.stringify opts}"

  mapWithKey = (obj, f) ->
    result = []
    for key, value of obj
      result.push f value, key
    result

  composePath = (path, opts) ->
    if opts
      params = mapWithKey opts, (v, k) -> "#{k}=#{v}"
      path + '?' + join params, '&'
    else
      path

  requestWithOpts = (path, opts, go) ->
    doGet (composePath path, opts), go

  encodeArray = (array) -> "[#{join (map array, encodeURIComponent), ','}]"

  requestInspect = (key, go) ->
    opts = key: encodeURIComponent key
    requestWithOpts '/Inspect.json', opts, go

  requestFrames = (go) ->
    doGet '/3/Frames.json', (error, result) ->
      if error
        go error
      else
        go null, result.frames

  requestFrame = (key, go) ->
    doGet "/3/Frames/#{encodeURIComponent key}", (error, result) ->
      if error
        go error
      else
        go null, head result.frames

  requestColumnSummary = (key, column, go) ->
    doGet "/3/Frames/#{encodeURIComponent key}/columns/#{column}/summary", go

  requestJobs = (go) ->
    doGet '/Jobs.json', (error, result) ->
      if error
        go new Flow.Error 'Error fetching jobs', error
      else
        go null, result.jobs 

  requestJob = (key, go) ->
    #opts = key: encodeURIComponent key
    #requestWithOpts '/Job.json', opts, go
    doGet "/Jobs.json/#{encodeURIComponent key}", (error, result) ->
      if error
        go new Flow.Error "Error fetching job '#{key}'", error
      else
        go null, head result.jobs

  requestFileGlob = (path, limit, go) ->
    opts =
      src: encodeURIComponent path
      limit: limit
    requestWithOpts '/Typeahead.json/files', opts, go

  requestImportFiles = (paths, go) ->
    tasks = map paths, (path) ->
      (go) ->
        requestImportFile path, go
    (Flow.Async.iterate tasks) go

  requestImportFile = (path, go) ->
    opts = path: encodeURIComponent path
    requestWithOpts '/ImportFiles.json', opts, go

  requestParseSetup = (sources, go) ->
    encodedPaths = map sources, encodeURIComponent
    opts =
      srcs: "[#{join encodedPaths, ','}]"
    requestWithOpts '/ParseSetup.json', opts, go

  requestParseFiles = (sourceKeys, destinationKey, parserType, separator, columnCount, useSingleQuotes, columnNames, deleteOnDone, checkHeader, go) ->
    opts =
      hex: encodeURIComponent destinationKey
      srcs: encodeArray sourceKeys
      pType: parserType
      sep: separator
      ncols: columnCount
      singleQuotes: useSingleQuotes
      columnNames: encodeArray columnNames
      checkHeader: checkHeader
      delete_on_done: deleteOnDone
    requestWithOpts '/Parse.json', opts, go

  requestModels = (go, opts) ->
    requestWithOpts '/3/Models.json', opts, (error, result) ->
      if error
        go error, result
      else
        go error, result.models

  requestModel = (key, go) ->
    doGet "/3/Models.json/#{encodeURIComponent key}", (error, result) ->
      if error
        go error, result
      else
        go error, head result.models

  requestModelBuilders = (algo, go) ->
    doGet "/2/ModelBuilders.json/#{algo}", go

  requestModelInputValidation = (algo, parameters, go) ->
    doPost "/2/ModelBuilders.json/#{algo}/parameters", parameters, go

  requestModelBuild = (algo, parameters, go) ->
    doPost "/2/ModelBuilders.json/#{algo}", parameters, go

  requestModelMetrics = (modelKey, frameKey, go) ->
    doPost "/3/ModelMetrics.json/models/#{encodeURIComponent modelKey}/frames/#{encodeURIComponent frameKey}", {}, go

  link _.requestInspect, requestInspect
  link _.requestFrames, requestFrames
  link _.requestFrame, requestFrame
  link _.requestColumnSummary, requestColumnSummary
  link _.requestJobs, requestJobs
  link _.requestJob, requestJob
  link _.requestFileGlob, requestFileGlob
  link _.requestImportFiles, requestImportFiles
  link _.requestImportFile, requestImportFile
  link _.requestParseSetup, requestParseSetup
  link _.requestParseFiles, requestParseFiles
  link _.requestModels, requestModels
  link _.requestModel, requestModel
  link _.requestModelBuilders, requestModelBuilders
  link _.requestModelBuild, requestModelBuild
  link _.requestModelInputValidation, requestModelInputValidation
  link _.requestModelMetrics, requestModelMetrics

