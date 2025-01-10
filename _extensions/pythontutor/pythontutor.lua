-- Generate a unique ID for each code block to avoid conflicts --
local random = math.random
function genID()
  return random(1000000000)
end

-- Include PythonTutor HTML dependencies --
-- These are just all the files required by the bare bones demo:
-- https://github.com/pathrise-eng/pathrise-python-tutor/blob/53253554f6fdb9176cb90e54df38b508d9529235/v3/demo.html
function includePythonTutorDeps(base)
  quarto.doc.add_html_dependency({
    name = "pythontutor",
    version = "1.0.0",
    scripts = {"html/js/d3.v2.min.js", "html/js/jquery-1.8.2.min.js", "html/js/jquery-ui-1.11.4/jquery-ui.min.js", "html/js/jquery.ba-bbq.min.js", "html/js/jquery.jsPlumb-1.3.10-all-min.js", "html/js/jquery.simplemodal.js", "html/js/pytutor.js"},
    stylesheets = {"html/css/basic.css", "html/css/pytutor.css", "html/js/jquery-ui-1.11.4/jquery-ui.css"},
    resources = {"html/js/images/ui-bg_glass_100_f6f6f6_1x400.png","html/js/images/ui-bg_highlight-soft_100_eeeeee_1x100.png","html/js/images/ui-icons_222222_256x240.png"}
  })
end


-- Write code block to file - execute pg_logger.py to generate trace --
-- Uses a modified version of generate_json_trace.py that writes to a file --
function genTrace(id, code)
  local filename = id.."temp.py"
  local file = io.open(filename, "w")
  file:write(code)
  file:close()

  local outputfile = id.."temp.json"
  local pg_logger = quarto.utils.resolve_path("generate_json_trace.py")
  local cmd = "python " .. pg_logger .. " " .. filename .. " " .. outputfile
  os.execute(cmd)

  local file = io.open(outputfile, "r")
  local json = file:read("*all")
  file:close()
  local obj = quarto.json.decode(json)

  -- This in particular seems like a bit of a hack,
  -- we've decoded the json, surely there's a way to include it without sticking it in a script tag?
  quarto.doc.include_text("in-header", [[
<script type="text/javascript">
var trace]]..id..[[ = ]] .. json .. [[;
</script>
]])

  quarto.doc.include_text("in-header", [[
<script type="text/javascript">
$(document).ready(function() {
  var myViz = new ExecutionVisualizer('pytutor]]..id..[[', trace]]..id..[[, {debugMode: true});
});
</script>
]])

  -- Clean up our mess
  os.remove(filename)
  os.remove(outputfile)
end



-- Convert code blocks to links to embedded Python Tutor visualizations --
function CodeBlock(elem)
  includePythonTutorDeps(quarto.utils.resolve_path(""))
  if elem.classes:includes('{pythontutor}') then
    local blockID = genID()
    genTrace(blockID, elem.text)

    local div = '<div id="pytutor'..blockID..'" style="width: 100%; height: 400px;"></div>'
    return pandoc.RawBlock('html', div)
  end
end






