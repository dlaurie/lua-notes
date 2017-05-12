-- Columnize Pandoc-generated table of contents 
-- Relies on simple layout as by Pandoc 1.16 for glossary.html: 
--   no nested <div> inside the TOC, one TOC item per line.

function main(arg)
  local toc, pre, post = {}, {}, {}
  local infilename = arg[1]
  local infile = infilename and io.open(infilename)
  local toc_done = nil

  local k=0
  while not toc_done do
    local line = infile:read()
    k=k+1
    if not line then break end
    if toc_done == nil then
      if line:match'^<div id="TOC">%s*$' then
        toc_done = false
      else pre[#pre+1] = line
      end
    else
      local item = line:match'<li>(.*)</li>' 
      if item then 
        toc[#toc+1] = item
      elseif line:match'</div>' then
        toc_done = true
      end
    end
  end

  while true do
    local line = infile:read()
    k=k+1
    if not line then break end
    post[#post+1] = line
  end    
  
  toc = columnize(toc,6)

  infile:close()
  infile = io.open(infilename,'w')
  
  infile:write(table.concat({
    table.concat(pre,"\n"), toc, table.concat(post,"\n") },"\n")
      .."\n"):close()
end

function columnize(text,ncol)
  local col, cols = {}, {}
  local quota = math.ceil(#text/ncol)
  cols[1] = '<table class="menubar" width="100%">\n<tr>'
  for k,v in ipairs(text) do
    col[#col+1] = v..'<br>' 
    if k%quota==0 or k==#text then
      cols[#cols+1] = table.concat(
       {"<td>",table.concat(col,"\n"),"</td>"},"\n")
      col = {}
    end
  end
  cols[#cols+1] = "</tr></table>"
  return table.concat(cols,"\n")
end

main(arg)
