debug = false
dbg = (msg) ->
    if debug isnt true
        return
    console.log(msg)

strip = (text) ->
    if text isnt undefined
        text.replace(/^\s+|\s+/g, "")
    else
        text

GetBlocks = (text) ->
    blocks = text.match(/(?:\[(.+?)\]{(.+?)})|(@.+)/g)
    if blocks is null
        return null
    len = blocks.length
    starts = (text.indexOf(blocks[b],0) for b in [0...len])
    lengths = (blocks[b].length for b in [0...len])
    ends = (starts[b] + lengths[b] for b in [0...len])
    {blocks,starts,ends}

GetVariables = (blocks) ->
    len = blocks.length
    names = []
    inits = []
    pattern = /\[(?:[A-z$]+)*([-\d.]+)[\s\w%]*\]{([\w]+):*/
    for b in [0...len]
        if blocks[b].startsWith("@") is false
            vars = pattern.exec(blocks[b])
            names[b] = strip(vars[2])
            if vars[1] isnt undefined
                inits[b] = strip(vars[1])
            else
                inits[b] = ""
    {names,inits}

GetTexts = (blocks) ->
    len = blocks.length
    formats = []
    texts = []
    pattern = /\[(?:[A-z$]+)*[-\d.]+(\s*[\w\d%]*)\]/
    for b in [0...len]
        if blocks[b].startsWith("@") is false
            raw = pattern.exec(blocks[b])[1]
            raw_split = raw.split(" ")
            if raw[0] is "%" and raw_split[0].length > 1
                formats[b] = raw_split[0]
                texts[b] = raw[formats[b].length...raw.length]
            else
                formats[b] = ""
                texts[b] = raw
    {texts,formats}

GetConfigs = (blocks,text) ->
    len = blocks.length
    # Types are: AdjustableNumber, Result
    types = []
    mins = []
    maxs = []
    steps = []
    conds = []
    exprs = []

    for b in [0...len]
        if blocks[b].startsWith("@") is false
            mins[b] = ""
            maxs[b] = ""
            steps[b] = ""
            conds[b] = ""
            exprs[b] = ""
            
            if ":" in blocks[b]
                pattern = /\[.+\]{.+:*\s([+-\d]+[\.]{2,3}[+-\d]+(?:\sby\s*[+-.\d]+)*)*}/
                config = pattern.exec(blocks[b])
            else # look for expressions tagged with @
                # Get variable
                pattern = /\[(?:[A-z$]+)*[-\d.]+[\s\w%]*\]{([\w]+)/
                varName = strip(pattern.exec(blocks[b])[1])

                pattern = new RegExp("(@" + varName + ".+)")
                config = [strip(pattern.exec(text)[1].split("=")[1].replace(/@/g,"")),"Result"]
            
            types[b] = GetConfigType(config)
            switch(types[b])
                when "Result"
                    exprs[b] = config[0].replace /([a-zA-Z_]+.*?)/g, (match) ->
                        AddThisTo(match)
                when "AdjustableNumber"
                    range_info = config[1].split("..")
                    step_info = range_info[1].split(" by ")
                    if step_info.length > 1
                        steps[b] = step_info[1]
                        mins[b] = range_info[0]
                        maxs[b] = step_info[0]
                    else
                        mins[b] = range_info[0]
                        maxs[b] = range_info[1]
    {types,mins,maxs,steps,conds,exprs}

GetConfigType = (config) ->
    if config[1].split("..").length > 1
        type = "AdjustableNumber"
    else if config[1] is "Result"
        type = "Result"
    else
        type = "Unknown"

AddThisTo = (text) ->
    if text is undefined
        return
    text = "this.#{text}"

GetHtmJs = (raw,blocks,variables,texts,configs) ->
    inits = ""
    updates = ""
    htm = raw[0..blocks['starts'][0] - 1]
    len = blocks['starts'].length - 1
    for b in [0..len]
        switch configs['types'][b]
            when "Result"
                updates += "#{AddThisTo(variables['names'][b])}=#{configs['exprs'][b]};"
                htm += "<span data-var=\"#{variables['names'][b]}\""
                htm += " data-format=\"#{texts['formats'][b]}\"" if texts['formats'][b] isnt ""
                htm += ">#{texts['texts'][b]}</span>"
            when "AdjustableNumber"
                if variables['inits'][b] isnt ""
                    inits += "#{AddThisTo(variables['names'][b])}=#{variables['inits'][b]};"
                else
                    inits += "#{AddThisTo(variables['names'][b])}=#{configs['mins'][b]};"
                htm += "<span data-var=\"#{variables['names'][b]}\""
                htm += " class=\"TKAdjustableNumber\" "
                htm += " data-min=\"#{configs['mins'][b]}\"" if configs['mins'][b] isnt ""
                htm += " data-max=\"#{configs['maxs'][b]}\"" if configs['maxs'][b] isnt ""
                htm += " data-step=\"#{configs['steps'][b]}\"" if configs['steps'][b] isnt ""
                htm += " data-format=\"#{texts['formats'][b]}\"" if texts['formats'][b] isnt ""
                htm += ">#{texts['texts'][b]}</span>"
        htm += raw[blocks['ends'][b]..blocks['starts'][b + 1] - 1] if (b <= len)
    js = "{initialize: function () {#{inits}},update: function (){#{updates}}}"
    {js,htm}

ParseReactive = (raw) ->
    try
        dbg("Get blocks")
        blocks = GetBlocks(raw)
        if blocks is null
            return null
        dbg("Get vars and inits")
        variables = GetVariables(blocks['blocks'])
        dbg("Get text and format")
        texts = GetTexts(blocks['blocks'])
        dbg("Get config info")
        configs = GetConfigs(blocks['blocks'],raw)
        dbg("Get js and htm")
        GetHtmJs(raw,blocks,variables,texts,configs)
    catch error
        dbg("Parsing Error #{error}")
        return null

tangle = {}
model = {}

MdToHtml = (raw) ->
    try
        converter = new Showdown.converter()
        htm = converter.makeHtml(raw)
    catch error
        dbg("Markdown convertion error #{error}")
        return raw


UpdateModel = (model) ->
    element = document.getElementById("t1")
    tangle = new Tangle(element,model)

RunParse = ->
    raw = "\n" + $("#input").val()
    r = ParseReactive(raw)
    if r isnt null
        try
            htm = MdToHtml(r['htm'])
            eval("model =" + r['js'])
            $("#output").html(htm)
            UpdateModel(model)
        catch error
            dbg("Model loading error #{error}")
            htm = MdToHtml(raw)
            $("#output").html(htm)
    else
        htm = MdToHtml(raw)
        $("#output").html(htm)

oldtext = ""
newtext = ""

CheckForChanges = ->
    newtext = $("#input").val()
    if newtext isnt oldtext
        RunParse()
    oldtext = newtext
    setTimeout CheckForChanges, 300

$ ->
    model =
        initialize: ->
            return
        update: ->
            return
    element = document.getElementById("t1")
    tangle = new Tangle(element,model)
    CheckForChanges()