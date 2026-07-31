@{
    # Sample menu data for the future Config module.
    # Core 0.1.0 does not load this automatically; Demo.ps1 builds menus in code.
    Title    = 'Sample Config Menu'
    Subtitle = 'Loaded from .psd1 when Config ships'
    Items    = @(
        @{
            Id     = 'hello'
            Label  = 'Say hello'
            Hotkey = 'h'
            # Action handlers are registered by the host (not embedded arbitrary code from untrusted files)
            Handler = 'Hello'
        }
        @{
            Id      = 'quit'
            Label   = 'Quit'
            Hotkey  = 'q'
            Handler = 'Quit'
        }
    )
}
