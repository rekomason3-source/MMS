-- Bitlings: First Spark — LÖVE configuration
-- Canonical canvas is 640x480 (R36S native). Desktop builds may resize; the
-- game letterboxes and scales the canonical canvas.

function love.conf(t)
  t.identity = "bitlings_first_spark" -- stable save identity (do not change)
  t.version = "11.5"
  t.console = false
  t.accelerometerjoystick = false
  t.gammacorrect = false

  t.window.title = "Bitlings: First Spark"
  t.window.width = 640
  t.window.height = 480
  t.window.minwidth = 320
  t.window.minheight = 240
  t.window.resizable = true
  t.window.vsync = 1
  t.window.msaa = 0
  t.window.highdpi = false
  -- PortMaster launcher sets BITLINGS_FULLSCREEN=1 on device
  t.window.fullscreen = os.getenv("BITLINGS_FULLSCREEN") == "1"

  -- Unused modules stay off to save memory and boot time on the R36S.
  t.modules.physics = false
  t.modules.video = false
  t.modules.touch = false
  t.modules.thread = false
  if os.getenv("BITLINGS_NOAUDIO") == "1" then
    t.modules.audio = false
    t.modules.sound = false
  end
end
