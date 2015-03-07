using ..Blink
import Blink: js, jsstring, id
import Base: position, size

export Window, flashframe, shell, progress, title,
  centre, floating, loadurl, opentools, closetools, tools,
  body, loadhtml, loadfile, css, front

type Window
  id::Int
  shell::Shell
  content
end

shell(win::Window) = win.shell
id(win::Window) = win.id

const window_defaults = @d(:url => "about:blank",
                           :title => "Julia",
                           "node-integration" => false,
                           "use-content-size" => true,
                           :icon => Pkg.dir("Blink", "deps", "julia.png"))

function Window(a::Shell, opts::Associative = Dict())
  content = nothing
  if !haskey(opts, :url)
    content = Page()
    opts[:url] = Blink.localurl(content)
  end
  id = @js a createWindow($(merge(window_defaults, opts)))
  return Window(id, a, content)
end

Window(opts::Associative = Dict()) = Window(shell(), opts)

function dot(w::Window, code; callback = true)
  r = js(shell(w), :(withwin($(w.id), $(jsstring(code)))),
         callback = callback)
  return callback ? r : w
end

dot_(args...) = dot(args..., callback = false)

macro dot (win, code)
  :(dot($(esc(win)), $(Expr(:quote, Expr(:., :this, code)))))
end

macro dot_ (win, code)
  :(dot_($(esc(win)), $(Expr(:quote, Expr(:., :this, code)))))
end

# Window management APIs

active(win::Window) =
  @js shell(win) windows.hasOwnProperty($(win.id))

flashframe(win::Window, on = true) =
  @dot_ win flashFrame($on)

progress(win::Window, p = -1) =
  @dot_ win setProgressBar($p)

title(win::Window, title) =
  @dot_ win setTitle($title)

title(win::Window) =
  @dot win getTitle()

centre(win::Window) =
  @dot_ win center()

position(win::Window, x, y) =
  @dot_ win setPosition($x, $y)

position(win::Window) =
  @dot win getPosition()

size(win::Window, w, h) =
  @dot_ win setSize($w, $h)

size(win::Window) =
  @dot win getSize()

floating(win::Window, flag) =
  @dot_ win setAlwaysOnTop($flag)

floating(win::Window) =
  @dot win isAlwaysOnTop()

loadurl(win::Window, url) =
  @dot win loadUrl($url)

loadfile(win::Window, f) =
  loadurl(win, "file://$f")

opentools(win::Window) =
  @dot win openDevTools()

closetools(win::Window) =
  @dot win closeDevTools()

tools(win::Window) =
  @dot win toggleDevTools()

front(win::Window) =
  @dot win showInactive()

# Window content APIs

active(::Nothing) = false

js(win::Window, s::JSString; callback = true) =
  active(win.content) ? js(win.content, s, callback = callback) :
    dot(win, :(this.webContents.executeJavaScript($(jsstring(s)))), callback = callback)

body(win::Window, html::String) =
  @js win document.body.innerHTML = $html

const initcss = """
  <style>html,body{margin:0;padding:0;border:0;text-align:center;}</style>
  """

function loadhtml(win::Window, html::String)
  tmp = string(tempname(), ".html")
  open(tmp, "w") do io
    println(io, initcss)
    println(io, html)
  end
  loadfile(win, tmp)
  @schedule (sleep(1); rm(tmp))
  return
end