@{
    Title    = 'Consumer App Menu'
    Subtitle = 'Edit this menu; keep Handler names mapped in App.ps1'
    Theme    = 'Dark'
    Items    = @(
        @{
            Id      = 'hello'
            Label   = 'Say hello'
            Hotkey  = 'h'
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
